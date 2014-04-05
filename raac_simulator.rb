# load params file
require_relative ARGV[0]

require 'pp'
require_relative 'requester'
require_relative 'traac'
require_relative 'raac'
require_relative 'plotter'

class Raac_Simulator

  def initialize
    # instantiate models
    @models = {}
    Parameters::MODELS.each { |model| @models[model.name] = model.new }
    # results
    @results = {}
    # generate the requesting agents
    @requesters = []
    Parameters::TYPES.each do |type, props| 
      props[:count].times do |i| 
        @requesters << Requester.new(type.to_s + i.to_s, 
                                     props[:sharing], 
                                     props[:obligation])
      end
    end
    
    # generate owners and their policies
    # just symbols, the traac class will keep more details
    @owners = []
    @policies = {}

    # replacement counter
    @replacement_counter = 0
    
    Parameters::OWNER_COUNT.times do |i| 
      requester_stack = @requesters.dup
      # shuffle for random zone assignment
      requester_stack.shuffle!
      id = "ow" + i.to_s
      @owners << id

      # assign requesters to zones - do this like dealing out cards
      @policies[id] = Hash.new { |hash, key| hash[key] = [] }
      while not requester_stack.empty?
        Parameters::ZONES.each do |zone|
          r = requester_stack.pop
          if not r == nil
            @policies[id][r.id] <<= zone
          end
        end
      end
    end
  end

  # get an individual from the given zone of a given user's policy
  def get_recipient_from_zone(owner, zone)
    @requesters.select { |r| @policies[owner][r.id][0] == zone }.sample
  end

  # get a recipient for a requester competent selectors are more
  # likely to get recipients from undefined_good, read or share
  # zones, while bad selectors will more likely get recipients from
  # the deny or undefined_bad zones
  def get_recipient(owner, requester)
    if rand <= requester.sharing_comp
      target_zones = [:share, :read, :undefined_good]
    else
      target_zones = [:deny, :undefined_bad]
    end
    return @requesters.select { |r| target_zones.include?(@policies[owner][r.id][0]) }.sample
  end

  # get a replacement agent with a new unique id
  def get_replacement
    # replace the agent that moved
    new_type_id = Parameters::TYPES.keys.sample
    @replacement_counter += 1
    Requester.new(new_type_id + replacement_counter.to_s, 
                  Parameters::TYPES[new_type_id][:sharing], 
                  props[new_type_id][:obligation])
  end


  def run
    # for each specified model, do the number of runs
    @models.each do |name, model|
      Parameters::RUNS.times do |run|
        run_results = []
        # run TIME_STEPS accesses against the system
        Parameters::TIME_STEPS.times do |t|
          timestep_result = 0.0
          #for each owner, generate a random request against his model
          @owners.each do |owner|
            requester = get_recipient_from_zone(owner, :share)
            recipient = get_recipient(owner, requester)
            request = { 
              owner: owner,
              requester: requester,
              recipient: recipient,
              sensitivity: Parameters::SENSITIVITY_TO_STRATEGIES.keys.sample
            }

            # do an access request, pass in policy
            result = model.authorisation_decision(request, @policies[owner])
            
            # if a good result, add bonus to timestep utility, if bad, remove
            # simulates realisation of risk/reward
            # if access is denied (through sharing) to someone in undefined_good, then bad
            update = Parameters::SENSITIVITY_TO_LOSS[request[:sensitivity]]
            # if access granted (through sharing) to someone in undefined_bad, then bad
            if result[:decision] && @policies[owner][recipient.id][0] == :undefined_bad then
              timestep_result -= update
              # if shared into read, share or undefined...
            elsif [:read, :share, :undefined_good].include?(@policies[owner][recipient.id][0])
              if result[:decision]
                # and access granted, positive utility update
                timestep_result += update
              else
                # and access denied, negative utility update
                timestep_result -= update
              end
            end

            # determine whether requester fulfils and restore budget agent
            # only gets one chance to ever fulfil, at this point - this
            # simulates that agents might complete the obligation, but might
            # never, and gives one variable to control this
            if rand <= request[:requester].obligation_comp
              model.do_obligation(request[:requester])
            end

            # if the recipient was in one of the undefined zones,
            # immediately move from there to the appropriate explicit zone,
            # before trust update ideally - then add a new agent to
            zone = @policies[owner][recipient.id]
            new_zone = zone
            if zone == :undefined_good
              new_zone = :read
            elsif zone == :undefined_bad
              new_zone = :deny
            end
            @policies[owner][recipient.id] = new_zone
            if zone != new_zone then @requesters << get_replacement end

            # end of foreach owner
          end
          # append timestep total to the array of results
          run_results << timestep_result / Parameters::OWNER_COUNT.to_f
        end
        # end of foreach timestep
        (@results[name] ||= []) << run_results
      end
    end
    
    # write results to csv and svg
    Plotter.writeout_results(@results)
    Plotter.plot_results
  end
end

rs = Raac_Simulator.new
rs.run
