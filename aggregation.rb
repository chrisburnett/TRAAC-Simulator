module Aggregation

  # Take a number of groups and compute an average trust expectation
  # for them in the simplest way possible, not weighted or anything
  # MOST NAIVE - affected by group size
  def average_expectation(trust_model, groups)
    sum, count = 0, 0
    groups.each do |group|
      group.each do |member|
        sum += trust_model.evaluate(member)
        count += 1
      end
    end
    sum / count
  end

    

end

  
