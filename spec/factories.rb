FactoryGirl.define do

  sequence :id do |n|
    "r#{n}"
  end

  factory :requester do
    id
    initialize_with { new(id, nil, nil, nil) }
  end

  factory :group do
    id
    initialize_with { new(id, nil) }
  end
  
end
