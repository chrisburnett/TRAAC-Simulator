require_relative 'sl_trust'
require_relative 'raac'

# this class models TRAAC behaviour but only using sharing trust, not
# obligation trust. That is, we are using trust and risk to find out
# which risk domain, but we are using risk budgets to determine when
# mitigation strategies cannot be used, static risk domains
class TraacSTOnly < Raac 

  def initialize
    super
    @sharing_history = Hash.new(Array.new)
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
    trust_model = DirectSLTrustModel.new
    violated = false
    @sharing_history[request[:owner]].each do |event| 
      # if this event is to do with the requester for which we are calculating
      evaluation = evaluate_request(event, policy)
      if event[:requester].id == request[:requester].id
        trust_model.add_evidence(request[:requester], evaluation)
      end

      # no-violation bonus - need to do a big search, if there isn't a
      # denied sharing event then plus - only one data item assumed so
      # only one possible increment
      if !evaluation then violated = true end
    end
    
    # if we never saw a violation then give the one point bonus
    if !violated then trust_model.add_evidence(request[:requester], true) end
    
    # recorded regardless of decision
    @sharing_history[request[:requester].id] << request

    # return expectation
    trust_model.evaluate(request[:requester])
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


