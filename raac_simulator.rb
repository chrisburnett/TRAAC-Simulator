# load params file
require_relative ARGV[0]

require 'pp'
require_relative 'requester'
require_relative 'traac'
require_relative 'raac'
require_relative 'plotter'

class Raac_Simulator

  def initialize
    # results
    @results = {}
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
  def get_zone(owner, zone)
    @requesters.select { |r| @policies[owner][r.id][0] == zone }
  end

  # get a recipient for a requester competent selectors are more
  # likely to get recipients from undefined_good, read or share
  # zones, while bad selectors will more likely get recipients from
  # the deny or undefined_bad zones
  def get_recipient(owner, requester)
    if rand <= requester.sharing_comp
      target_zones = [:undefined_good]
    else
      target_zones = [:undefined_bad]
    end
    return @requesters.select { |r| target_zones.include?(@policies[owner][r.id][0]) }.sample
  end

  # get a replacement agent with a new unique id
  def get_replacement(type_id)
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
      Parameters::RUNS.times do |run|
        # reset experiment and model state between runs
        setup
        # instantiate a new model
        model = model_class.new
        run_results = []
        # run TIME_STEPS accesses against the system
        Parameters::TIME_STEPS.times do |t|
          timestep_result = 0.0
          #for each owner, generate a random request against his model
          @owners.each do |owner|
            requester = get_zone(owner, :share).sample
            recipient = get_recipient(owner, requester)
            request = { 
              owner: owner,
              requester: requester,
              recipient: recipient,
              sensitivity: Parameters::SENSITIVITY_TO_STRATEGIES.keys.sample
            }

            # do an access request, pass in policy
            result = model.authorisation_decision(request, @policies[owner])



            #pp result
            # if a good result, add bonus to timestep utility, if bad, remove
            # simulates realisation of risk/reward
            # if access is denied (through sharing) to someone in undefined_good, then bad
            update = Parameters::SENSITIVITY_TO_LOSS[request[:sensitivity]]
            # if access granted (through sharing) to someone in undefined_bad, then bad
            if result[:decision]
              if @policies[owner][recipient.id][0] == :undefined_bad then
                timestep_result -= update
              # if shared into read, share or undefined...
              elsif @policies[owner][recipient.id][0] == :undefined_good then
                timestep_result += update
              end
            elsif @policies[owner][recipient.id][0] == :undefined_good then
              # and access denied, negative utility update
              #timestep_result -= update
            end
          end

          
          # deal with obligations
          @requesters.each do |requester| 
            # at every time step there's a chance that agents will deal with obligations
            prob = rand
            if prob < Parameters::OBLIGATION_TIMEOUT_PROB
              model.fail_obligation(requester)
            end
            
            if prob < requester.obligation_comp
              model.do_obligation(requester)
            end
          end
          
          # append timestep total to the array of results
          run_results << timestep_result / Parameters::OWNER_COUNT.to_f
        end

        # end of foreach timestep
        (@results[model_class.name] ||= []) << run_results
      end
      print '.'
    end
    
    # write results to csv and svg
    Plotter.writeout_results(@results)
    Plotter.plot_results
  end
end



rs = Raac_Simulator.new
rs.run
