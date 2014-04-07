# this class models RAAC behaviour without trust (i.e. risk budgets and static intervals)
class Raac
  
  def initialize
    # superclasses can override this value, setting to 0 to disable risk budgeting
    @budget_decrement = Parameters::BUDGET_DECREMENT
    # track obligations
    @active_obligations = Hash.new { |h,k| h[k] = [] }
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
    # check for deny zone and check the user has enough budget for this owner
    # (instant deny conditions)
    if policy[request[:recipient]][0] != :deny &&
        request[:requester].risk_budget[request[:owner]] > 0
      # now check to see which risk domain the computed risk falls into
      risk_domains(request).each do |did, domain| 
        if risk >= domain[0] && risk < domain[1] then
          # set the obligation to whatever the mitigation strategy says for this risk domain
          obligation = Parameters::MITIGATION_STRATEGIES[ms][did]

          # if there was an obligation, decrease budget and add it to
          # the active list for this agent
          if obligation != :none then
            add_obligation(request[:requester], obligation, request[:owner])
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

    # return lots of information
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
      req_budget: request[:requester].risk_budget[request[:owner]]
    }
  end
  
  def add_obligation(requester, obligation, owner)
    @active_obligations[requester].push([obligation, owner])
    requester.risk_budget[owner] -= @budget_decrement
  end
  
  def do_obligation(requester)
    # if this requester has any open obligations, do one and restore
    # budget
    ob = @active_obligations[requester].pop
    if ob != nil then requester.risk_budget[ob[1]] += @budget_decrement end
  end

  # failing an obligation is when it times out and it's not longer
  # possible to get your budget back
  def fail_obligation(requester)
    @active_obligations[requester].pop
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
    
    # 0 because to use the actual risk makes the system more cautious
    # than our premissive mode, and since we don't punish bad
    # blocking, it will always do better.
  end

  # get the risk domains, possibly adjusting for trust
  def risk_domains(request)
    Parameters::RISK_DOMAINS
  end


end


