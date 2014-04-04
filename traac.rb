require_relative 'sl_trust'
require_relative 'raac'

# this class models TRAAC behaviour but only using sharing trust, not
# obligation trust. That is, we are using trust and risk to find out
# which risk domain, but we are using risk budgets to determine when
# mitigation strategies cannot be used, static risk domains
class TraacSTOnly < Raac 

  def initialize
    super
    @trust_models = Hash.new(DirectSLTrustModel.new)
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
    tm = @trust_models[request[:requester].id]
    # evaluate and add result to the trust model
    tm.add_evidence(request[:requester], 
                    evaluate_request(event, policy))
    
    # return expectation
    tm.evaluate(request[:requester])
  end

  # the evaluation function
  # positive if shared into read/share/undefined_good
  # negative if shared into deny/undefined_bad (else?)
  def evaluate_request(request, policy)
    if [:read, :share, :undefined_good].include? policy[request[:recipient].id]
      true
    else
      false
    end    
  end

end


