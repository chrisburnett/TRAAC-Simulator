# -*- coding: utf-8 -*-
# this class models the subjective logic trust model in direct mode
# non-additive beta with prior, basically

class DirectSLTrustModel

  attr_reader :evidence, :ratings

  def initialize(prior)
    # store of positive/negative observations after interactions
    @evidence = Hash.new { |hash, key| hash[key] = {r: 0.0, s: 0.0}}
    # store of apriori values for agents
    @prior = prior
  end

  # evaluate an agent and cache its rating
  def evaluate(agent)
    compute_expectation(compute_opinion(@evidence[agent], @prior))
  end

  def add_evidence(agent, outcome)
    if outcome == true then
      @evidence[agent][:r] += 1 
    elsif outcome == false then
      @evidence[agent][:s] += 1
    end
  end

  def remove_evidence(agent, outcome)
    if outcome then
      @evidence[agent][:r] -= 1 
    else
      @evidence[agent][:s] -= 1
    end
  end

  # return an SL opinion from the R and S parameters
  def compute_opinion(evidence, prior)
    {
     b: evidence[:r] / (evidence[:r] + evidence[:s] + 2),
     d: evidence[:s] / (evidence[:r] + evidence[:s] + 2),
     u: 2 / (evidence[:r] + evidence[:s] + 2),
     a: @prior
    }
  end

  def compute_expectation(opinion)
    # e = b + (u * a)
    opinion[:b] + (@prior * opinion[:u])
  end

  # get evidence pair for an agent
  def get_evidence(agent)
    @evidence[agent]
  end


end
