require_relative 'sl_trust'
require_relative 'raac'

# this class models TRAAC behaviour but only using sharing trust, not
# obligation trust. That is, we are using trust and risk to find out
# which risk domain, but we are using risk budgets to determine when
# mitigation strategies cannot be used, static risk domains
class TraacSTOnly < Raac 

  def initialize
    super
    @trust_models = 
      Hash.new { |h,k| h[k] = DirectSLTrustModel.new(Parameters::ST_PRIOR) }
    # FIXME these trust models *should* be conditional on the obligation, but we are assuming only one obligation for now, so everything is hardcoded around that
  end

  private

  # this is the only thing that changes from the Raac model - we
  # compute risk if we are computing the risk of a request, it means
  # it's been requested...  add it to the history
  def compute_risk(request, policy)
    # standard risk formulation
    # get the risk and multiply by 1-trust
    loss = Parameters::SENSITIVITY_TO_LOSS[request[:sensitivity]]
    trust = compute_trust(request, policy)
    (1-trust)*loss
  end

  def compute_trust(request, policy)
    # get the trust rating for this requester
    tm = @trust_models[request[:owner]]
    # evaluate and add result to the trust model
    tm.add_evidence(request[:requester], 
                    evaluate_request(request, policy))
    
    # return expectation
    tm.evaluate(request[:requester])
  end

  # the evaluation function
  # positive if shared into read/share/undefined_good
  # negative if shared into deny/undefined_bad (else?)
  def evaluate_request(request, policy)
    if [:undefined_good, :read, :share].include? policy[request[:recipient].id][0]
      true
    elsif [:undefined_bad, :deny].include? policy[request[:recipient].id][0]
      false
    else
      nil
    end    
  end

end


class TraacSTOT < TraacSTOnly

  def initialize
    super
    @ot_trust_models = Hash.new { |h,k| h[k] = 
      DirectSLTrustModel.new(Parameters::OT_PRIOR) }
    # disable budgeting
    @budget_decrement = 0
  end

  # need to scale the risk domains
  # 
  def risk_domains(request)
    requester = request[:requester]
    # retrieve OT trust model for requester
    tm = @ot_trust_models[requester.id]
    # get expectation of fulfillment
    ot = tm.evaluate(requester)
    # now we have a trust value, push all the left-hand points of the
    # risk domains to the left, to account for adjusting risk
    # mitigation. We don't really need to scale them all, only the
    # obligation zones
    old_domains = Parameters::RISK_DOMAINS
    new_domains = {}
    old_domains.each { |k,v| new_domains[k] = v.dup }

    # shrink the obligation interval...
    delta = (1-ot) * (old_domains[:d2][1] - old_domains[:d2][0])
    new_domains[:d2][1] = old_domains[:d2][1] - delta
    # stitch up the new boundaries, expanding the deny interval
    new_domains[:d3][0] = new_domains[:d2][1]

    # only modify d2! only obligation-domain
    
                             
    # labels = old_domains.keys
    # # Ruby 1.9 - values are returned in order of addition, nice
    # old_domains.each do |label, domain| 
    #   # get the next domain after this one
    #   next_domain = old_domains[labels[labels.index(label) + 1]]
    #   # get the amount to move
    #   if next_domain
    #     delta = ot * (domain[1] - domain[0])
    #     # add to new domain list
    #     new_domains[label] = [domain[0], domain[1] - delta]
    #   else
    #     # if we are on the last domain, we don't expand this one so
    #     # just add it as is
    #     new_domains[label] = domain
    #   end

    #oputs "#{new_domains} - ot: #{ot} - rq: #{requester.id} - #{delta}"
    return new_domains
  end
  
  # when an obligation is accepted, it's 'failed' until done
  # stacking up heaps of unsatisfied obligations will be noticed
  def add_obligation(requester, obligation)
    super
    tm = @ot_trust_models[requester.id]
    tm.add_evidence(requester, false)
  end
  
  # completing/failing obligations updates trust
  # positive update for completion
  def do_obligation(requester)
    super
    tm = @ot_trust_models[requester.id]
    # remove one of the negatives given for not yet satisfying
    tm.remove_evidence(requester, false)
    tm.add_evidence(requester, true)
  end

  # pop off an obligation but also update trust to record that it
  # failed and will never be done
  def fail_obligation(requester)
    super
    tm = @ot_trust_models[requester.id]
    tm.add_evidence(requester, false)    
  end

end
