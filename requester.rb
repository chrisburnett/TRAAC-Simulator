class Requester
  
  attr_accessor :id, :sharing_comp, :obligation_comp, :type

  def initialize(id, sharing_comp, obligation_comp, type)
    @id = id
    @sharing_comp = sharing_comp
    @obligation_comp = obligation_comp
    @type = type
  end
  
end
