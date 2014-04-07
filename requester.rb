class Requester
  
  attr_accessor :id, :sharing_comp, :obligation_comp, :type, :risk_budget

  def initialize(id, sharing_comp, obligation_comp, type)
    @id = id
    @sharing_comp = sharing_comp
    @obligation_comp = obligation_comp
    @type = type
    # requester remembers risk budget for each owner
    @risk_budget = Hash.new(Parameters::INITIAL_BUDGET)
  end
  
end
