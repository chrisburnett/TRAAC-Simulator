# this class models RAAC behaviour without trust (i.e. risk budgets and static intervals)
class Raac

  def initialize
    # superclasses can override this value, setting to 0 to disable risk budgeting
    @budget_decrement = Parameters::BUDGET_DECREMENT
    # track obligations
    @active_obligations = Hash.new { |h,k| h[k] = [] }
  end

  # This function returns a pair of decision (true or false) and an obligation (can be "none")
  def authorisation_decision(request, groups, ind_policy, grp_policy)
    obligation = :none
    decision = false
    fdomain = Parameters::REJECT_DOMAIN
    
    # first off, check the requester is even allowed to share. At the
    # moment, this should always be true, because the simulator is
    # only passing in agents from the share zone but just for
    # completeness
    if ind_policy[request[:requester].id] == :share then  
      # compute the risk
      risk = compute_risk(request, ind_policy, grp_policy)

      # get the mitigation strategy for the permission mentioned in the request
      ms = Parameters::SENSITIVITY_TO_STRATEGIES[request[:sensitivity]]

      # get the individual and group policy zones this recipient
      # belongs to TODO: if a recipient can be members of multiple
      # groups, how do we handle access checking? I think we need to
      # check all the groups, and see if any are deny. If not (meaning
      # all the recipient's groups are either undefined or read/share)
      # then group access is allowable.
      ind_zone = ind_policy[request[:recipient].id]
      grp_zone = grp_policy[groups[request[:recipient]]]

      # check for deny zone and check the user has enough budget for
      # this owner (instant deny conditions)
      if ind_zone != :deny &&
         request[:requester].risk_budget[request[:owner]] > 0
        # if the individual zone is explicitly defined (and not deny)

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
    end

    # the recipient might be a group, in which case it's already just
    # a symbol and we don't need to call ID (like we do for
    # individuals) TODO: to fix this, you'd really need to make groups
    # a class that responds to 'id'. Not a tidy solution, this, but
    # it'll do for now
    recipient = if request[:recipient].respond_to?(:id) then
                  request[:recipient].id
                else
                  request[:recipient]
                end
    
    # return lots of information
    return {
      decision: decision,
      risk: risk,
      obligation: obligation,
      domain: fdomain,
      strategy: ms,
      requester: request[:requester].id,
      recipient: recipient,
      source_zone: ind_policy[request[:requester].id],
      target_zone: ind_policy[request[:recipient].id],
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
  def compute_risk(request, ind_policy, grp_policy)
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
