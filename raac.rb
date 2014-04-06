# this class models RAAC behaviour without trust (i.e. risk budgets and static intervals)
class Raac
  
  def initialize
    # risk budgets - all agents start with same initial budget
    @risk_budgets = Hash.new(Parameters::INITIAL_BUDGET)
    # superclasses can override this value, setting to 0 to disable risk budgeting
    @budget_decrement = Parameters::BUDGET_DECREMENT
  end

  # This function returns a pair of decision (true or false) and an obligation (can be "none")
  def authorisation_decision(request, policy)
    # compute the risk
    risk = compute_risk(request, policy)

    # get the mitigation strategy for the permission mentioned in the request
    ms = Parameters::SENSITIVITY_TO_STRATEGIES[request[:sensitivity]]

    obligation = :none
    decision = false
    fdomain = Parameters::REJECT_DOMAIN
    # check for deny zone and check the user has enough budget
    # (instant deny conditions)
    if policy[request[:recipient]][0] != :deny &&
        @risk_budgets[request[:requester]] > 0
      # now check to see which risk domain the computed risk falls into
      risk_domains(request).each do |did, domain| 
        if risk >= domain[0] && risk < domain[1] then
          # set the obligation to whatever the mitigation strategy says for this risk domain
          obligation = Parameters::MITIGATION_STRATEGIES[ms][did]
          # if an obligation (auto-accepted) then decrease budget
          if obligation != :none then
            # simulate possible completion by only deducting the
            # budget if there is a failure
            if rand <= 1-request[:requester].obligation_comp then
              fail_obligation(request[:requester])         
            else
              do_obligation(request[:requester])
            end
          end

          # if we are in the last domain then reject the request,
          # otherwise accept (poss. with obligation)
          if did == Parameters::REJECT_DOMAIN then 
            decision = false 
          else decision = true 
          end
          # record this just for logging in the result
          fdomain = did
        end
      end
    end

    
    return {
      decision: decision,
      risk: risk,
      obligation: obligation, 
      domain: fdomain,
      strategy: ms, 
      requester: request[:requester].id,
      recipient: request[:recipient].id,
      source_zone: policy[request[:requester].id][0], 
      target_zone: policy[request[:recipient].id][0],
      req_budget: @risk_budgets[request[:requester]]
    }
  end

  def do_obligation(requester)
  end

  def fail_obligation(requester)
    @risk_budgets[requester] -= @budget_decrement
  end
  
  private

  # This function is where everything happens - we take all the things
  # which are happening in the domain and the context and compute a
  # risk value - OUR CONTRIBUTION WILL GO HERE
  def compute_risk(request, policy)
    # how is this done in Liang's paper?  there isn't risk computation
    # - so we need to use some kindof approximation let's adopt a
    # simple approach - trust is 0 for everyone so risk is always just
    # the risk for the sensitivity label
    Parameters::SENSITIVITY_TO_LOSS[request[:sensitivity]]
    0
    # 0 because to use the actual risk makes the system more cautious
    # than our premissive mode, and since we don't punish bad
    # blocking, it will always do better.
  end

  # get the risk domains, possibly adjusting for trust
  def risk_domains(request)
    Parameters::RISK_DOMAINS
  end


end


