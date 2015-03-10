# Load params file
require_relative ARGV[0]

require 'pp'
require 'pry'
require_relative 'requester'
require_relative 'traac'
require_relative 'raac'
require_relative 'plotter'
require_relative 'group'

class Raac_Simulator

  def initialize
    # results
    @results = {}
    @type_results = {}
    # instantiate models
    setup
  end

  def setup
    # generate the requesting agents
    @requesters = []
    Parameters::TYPES.each do |type, props|
      props[:count].times do |i|
        @requesters << Requester.new(type.to_s + i.to_s,
                                     props[:sharing],
                                     props[:obligation],
                                     type)
      end
    end

    @groups = {}
    # for each requester, and each group, roll a dice and see if the
    # requester should be in that group. Note that this allows
    # requesters to be in multiple groups at the same time, but that's
    # fine and probably even realistic. If there are no groups in the
    # parameters file, then this bit will do nothing.
    # map agents to group symbols
    if not Parameters::GROUPS.empty?
      @requesters.each do |agent|
        Parameters::GROUPS.each do |group, probs|
          if rand < probs[agent.type] then
            if not @groups[agent] then @groups[agent] = [] end
            # at the moment, we are not generating 'instances' of
            # groups, so the id and type are the same
            @groups[agent] << group
          end
        end
      end
    end

    # generate owners and their policies
    # just symbols, the traac class will keep more details
    @owners = []
    @policies = {}
    @group_policies = {}
    @policy_zones = {}
    @group_policy_zones = {}
    # replacement counter
    @replacement_counter = 0

    Parameters::OWNER_COUNT.times do |i|
      requester_stack = @requesters.dup
      group_stack = Parameters::GROUPS.keys
      # shuffle for random zone assignment
      requester_stack.shuffle!
      group_stack.shuffle!
      id = "ow" + i.to_s
      @owners << id

      # assign requesters to zones - do this like dealing out cards
      # this should end up with a roughly equal distribution across
      # zones
      @policies[id] = Hash.new { |hash, key| hash[key] = [] }
      while not requester_stack.empty?
        Parameters::ZONES.each do |zone|
          r = requester_stack.pop
          if not r == nil
            @policies[id][r.id] = zone
          end
        end
      end

      # assign groups to zones in the same way - in this way we need
      # at least four groups to ensure that we don't get null
      # requestors in the group cases TODO: we will need to handle
      # this anyway
      @group_policies[id] = Hash.new { |hash, key| hash[key] = [] }
      while not group_stack.empty?
        Parameters::ZONES.each do |zone|
          g = group_stack.pop
          if not g == nil
            @group_policies[id][g] = zone
          end
        end
      end

      # optimisation - create another structure to maintain the
      # policies as sets - doesn't cause a problem as we are not
      # changing the policy. This is so we can ask 'is such and such
      # in zone z of agent a?'  NOTE: we'd have to watch this if we
      # had dynamicity
      @policy_zones[id] = {}
      Parameters::ZONES.each do |zone|
        @policy_zones[id][zone] = @requesters.select { |r| @policies[id][r.id] == zone }
      end
      @group_policy_zones[id] = {}
      Parameters::ZONES.each do |zone|
        @group_policy_zones[id][zone] = Parameters::GROUPS.select { |g| @group_policies[id][g] == zone }
      end
    end
  end


  # get a recipient for a requester competent selectors are more
  # likely to get recipients from undefined_good, read or share
  # zones, while bad selectors will more likely get recipients from
  # the deny or undefined_bad zones
  def get_recipient(owner, requester, group = false)

    if rand <= requester.sharing_comp
      target_zones = [:undefined_good]
    else
      target_zones = [:undefined_bad]
    end
    # if we are looking to generate a recipient which is a group, look up the group policy
    if group
      # get a group id from the target zone of the owner's policy
      group_id = Parameters::GROUPS.select { |g| target_zones.include?(@group_policies[owner][g])}.keys.sample
      Group.new(group_id.to_s, group_id)
    else
      return @requesters.select { |r| target_zones.include?(@policies[owner][r.id]) }.sample
    end
  end

  # get a replacement agent with a new unique id
  def get_replacement(type_id, group_id)
    # replace the agent that moved
    @replacement_counter += 1
    Requester.new("n" + type_id.to_s + @replacement_counter.to_s,
                  Parameters::TYPES[type_id][:sharing],
                  Parameters::TYPES[type_id][:obligation],
                  type_id
                 )
  end


  def run
    # for each specified model, do the number of runs
    Parameters::MODELS.each do |model_class|
      puts model_class.name
      supersneakyresults = [0,0]
      Parameters::RUNS.times do |run|
        # reset experiment and model state between runs
        setup
        # instantiate a new model
        model = model_class.new
        run_results = []
        sneakyresult = [0,0]
        # run TIME_STEPS accesses against the system
        Parameters::TIME_STEPS.times do |t|
          timestep_result = 0.0

          #for each owner, generate a random request against his model
          @owners.each do |owner|
            # draw a request type randomly from those which are active
            type = Parameters::REQUEST_TYPES.sample
           
            # now select requester in the GI/GG case, we want to
            # select agents who are members of a group that is allowed
            # to share, but are individually undefined, to explicitly
            # test the group risk assessment model. If we can't find
            # such an agent, just sample the individual share zone.
            
            requester = if [:gi, :gg].include? type then
                          requester_group = @group_policy_zones[owner][:share].keys.sample
                          group_share_requesters = @groups.select { |a,g| g.include? requester_group }
                          ag = group_share_requesters.
                              select { |a| not @policy_zones[owner][:share].include? a }
                              .keys.sample
                          if not ag
                            @policy_zones[owner][:share].sample
                          else
                            ag
                          end
                        else
                          @policy_zones[owner][:share].sample
                        end

            # recipients:
            recipient = if [:ii, :gi].include? type then
                          get_recipient(owner, requester, group = false)
                        else
                          get_recipient(owner, requester, group = true)
                        end

            # We don't need to specify what they type of the request
            # is *in* the request object, because the model will
            # decide that for itself. It will decide whether to decide
            # access on the basis of individual or group policy, and
            # the recipient can be asked whether it is an individual
            # or group via .group?

            # only proceed if we are able to find a recipient and a
            # requester

            if recipient and requester
              request = {
                owner: owner,
                requester: requester,
                recipient: recipient,
                sensitivity: Parameters::SENSITIVITY_TO_STRATEGIES.keys.sample
              }

              # do an access request, pass in individual and group
              # policy and group assignments
              result = model.authorisation_decision(request, @groups, @policies[owner], @group_policies[owner])

              # if a good result, add bonus to timestep utility, if bad, remove
              # simulates realisation of risk/reward
              # if access is denied (through sharing) to someone in undefined_good, then bad
              update = Parameters::SENSITIVITY_TO_LOSS[request[:sensitivity]]

              # if access granted (through sharing) to someone in undefined_bad, then bad
              if result[:decision]
                if @policies[owner][recipient.id] == :undefined_bad then
                  timestep_result -= update.to_f
                  sneakyresult[0] += update.to_f

                # if shared into read, share or undefined...
                elsif @policies[owner][recipient.id] == :undefined_good then
                  timestep_result += update.to_f
                  sneakyresult[1] += update.to_f

                end
              elsif @policies[owner][recipient.id] == :undefined_good then
                # and access denied, negative utility update
                # timestep_result -= update
              end
            end
          end

          # deal with obligations
          @requesters.each do |requester|
            # at every time step there's a chance that agents will deal with obligations
            if rand < requester.obligation_comp
              model.do_obligation(requester)
            end
            if rand < Parameters::OBLIGATION_TIMEOUT_PROB
              model.fail_obligation(requester)
            end

          end

          # append timestep total to the array of results
          run_results << timestep_result.to_f / Parameters::OWNER_COUNT.to_f
          supersneakyresults[0] += sneakyresult[0]
          supersneakyresults[1] += sneakyresult[1]
        end

        # end of foreach timestep
        (@results[model_class.name] ||= []) << run_results
        #print "."
      end
      #print "\n"
      #supersneakyresults.map! { |r| (r / Parameters::RUNS) / Parameters::TIME_STEPS }
      #puts supersneakyresults

    end
    # write results to csv and svg
    Plotter.writeout_results(@results)
    Plotter.plot_results
  end
end



rs = Raac_Simulator.new
rs.run
