# -*- coding: utf-8 -*-
# this class models the subjective logic trust model in direct mode
# non-additive beta with prior, basically

class DirectSLTrustModel

  attr_reader :evidence, :ratings

  def initialize
    # store of positive/negative observations after interactions
    # r is initially 1 because of innocent until proven guilty
    # will be removed on first violation
    @evidence = Hash.new({r: 1.0, s: 0.0})
    # store of apriori values for agents
    @priors = Hash.new(0.5)
    # opinion is belief, disbelief, uncertainty and apriori
    @opinions = Hash.new({b: 0.0, d: 0.0, u: 1.0, a: 0.5})
  end

  # evaluate an agent and cache its rating
  def evaluate(agent)
    compute_expectation(compute_opinion(@evidence[agent], @priors[agent]))
  end

  def add_evidence(agent, outcome)
    if outcome then
      @evidence[agent][:r] += 1 
    else
      @evidence[agent][:s] += 1
      # check if this is first violation - if so remove IUPG bonus
      if @evidence[agent][:s] == 1
        @evidence[agent][:r] -= 1 
      end
    end
  end

  # return an SL opinion from the R and S parameters
  def compute_opinion(evidence, prior)
    {
     b: evidence[:r] / (evidence[:r] + evidence[:s] + 2),
     d: evidence[:s] / (evidence[:r] + evidence[:s] + 2),
     u: 2 / (evidence[:r] + evidence[:s] + 2),
     a: prior
    }
  end

  def compute_expectation(opinion)
    # e = b + (u * a)
    opinion[:b] + (opinion[:a] * opinion[:u])
  end

  # get evidence pair for an agent
  def get_evidence(agent)
    @evidence[agent]
  end


end
