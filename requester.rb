class Requester
  
  attr_accessor :id, :sharing_comp, :obligation_comp

  def initialize(id, sharing_comp, obligation_comp)
    @id = id
    @sharing_comp = sharing_comp
    @obligation_comp = obligation_comp
  end
  
end
