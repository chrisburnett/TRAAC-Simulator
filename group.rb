class Group
  
  attr_accessor :id, :type

  def initialize(id, type)
    @id = id
    @type = type
  end

  def group?
    true
  end
  
end
