# this class models RAAC behaviour without trust (i.e. risk budgets and static intervals)
class Raac

  def initialize
    # superclasses can override this value, setting to 0 to disable risk budgeting
    @budget_decrement = Parameters::BUDGET_DECREMENT
    # track obligations
    @active_obligations = Hash.new { |h,k| h[k] = [] }
  end


  # Check whether requester can share
  # Is in individual deny zone?
  # Yes: deny
  # Is in individual share zone?
  # Yes: goto 2
  # No: is individual in a group which is in group share zone?
  # Yes: goto 2
  # No: deny

  # Check whether recipient can be shared with
  # Is in individual deny zone?
  # Yes: deny
  # Is in individual read/share zone?
  # Yes: allow (still entails risk!)
  # Is individual in group which is in group deny zone?
  # Yes: deny
  # Is individual in group which is in group read/share zone?
  # Yes: allow (still entails risk!)
  # No: goto 3

  # Compute risk of sharing
  # Compute group trust
  # Compute individual trusts from groups and aggregate SOMEHOW
  # Compute group+individual trust for individual (using group trust as apriori)
  # Compute risk using combined (using loss values)
  # Allow requester to choose a risk mitigating obligation
  # What kind of RMO was chosen?
  # Individual?
  # mitigate risk using individual O-Trust
  # return decision (entails risk)
  # Group?
  # mitigate risk using Group O-Trust of the group to which the obligation was deferred
  # return decision (entails risk)
  # Monitor for fulfilment and update all O-Trust and S-Trust

  # TODO: UNIT TEST
  def new_authorisation_decision(request, ind_policy, grp_policy, groups)
    requester = request[:requester]
    recipient = request[:recipient]

    ind_requester_zone = ind_policy[requester.id]

    # NOTE: this needs check the right policy recipient can be a
    # group, which means that the 'individual' assignment actually
    # comes from the group policy
    ind_recipient_zone = if recipient.group? then
                           grp_policy[recipient.id]
                         else
                           ind_policy[recipient.id]
                         end

    # check for individual deny conditions - if the user is not in the
    # share zone individually then they need to have a group
    # assignment in the share zone
    if ind_requester_zone != :share then
      if ind_requester_zone == :deny then return false
      elsif groups[requester].
          select { |group| grp_policy[group] == :share }.
          empty? then return false
      end
    end

    # check whether recipient can receive
    # if in ind. deny zone  - deny
    if ind_recipient_zone == :deny then return false
    elsif [:read, :share].include? ind_recipient_zone then
      return true # allow if recipient can read or share
    else
      # reject if any of recipients groups are in deny
      groups[recipient].each do |g|
        if grp_policy[g] == :deny then return false end
      end

      # allow if no deny zone groups and at least one share/read zone
      # group
      groups[recipient].each do |g|
        if [:read,:share].include? grp_policy[g] then return true end
      end
    end

    # at this point, it should be the case that the requester is
    # either in the individual share zone OR is in a group which is in
    # the group share zone, and the recipient is in the undefined zone
    # individually and is not in any groups which are explicitly in
    # the group deny zone
    
  end

  # This function returns a pair of decision (true or false) and an obligation (can be "none")
  def authorisation_decision(request, groups, ind_policy, grp_policy)
    decision = false
    obligation = :none
    fdomain = nil
    # check the requester is even allowed to share. At the
    # moment, this should always be true, because the simulator is
    # only passing in agents from the share zone but just for
    # completeness
    if ind_policy[request[:requester].id] == :share then
      # compute the risk
      risk = compute_risk(request, ind_policy, grp_policy)

      # get the mitigation strategy for the permission mentioned in the request
      ms = Parameters::SENSITIVITY_TO_STRATEGIES[request[:sensitivity]]

      # get the individual zone this recipient
      # belongs to
      ind_zone = ind_policy[request[:recipient].id]

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
            fdomain = did
          end
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
      recipient: request[:recipient],
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
