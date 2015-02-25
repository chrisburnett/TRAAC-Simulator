require_relative 'traac'
require_relative 'raac'

module Parameters

  TIME_STEPS = 500
  RUNS = 10
  
  # how many data owners to use and evaluate
  OWNER_COUNT = 200
  
  # experimental condition (RAAC classes)
  MODELS = [Raac,TraacSTOnly,TraacSTOT]

  # settings for the data owners, data objects and policies

  # in the paper, we have owners coming back and reassessing undefined
  # sharing at a later time. We don't want to do this so we define two
  # undefined zones, representing the user's post-sharing preferences,
  # and allow the trust model to immediately update. This is
  # equivalent to the data owner classifying a sharing action as good
  # or bad immediately after the sharing (into undefined) has been
  # done.
  ZONES = [:share, :read, :deny, :undefined_good, :undefined_bad]

  RISK_DOMAINS = {
    d1: [0.0,0.2],
    d2: [0.2,0.6],
    d3: [0.6,1.0]
  }


  SENSITIVITY_TO_LOSS = {
    low: 0.2,
    med: 0.5,
    high: 1
    # low: 0.5,
    # med: 0.5,
    # high: 0.5
  }


  # this is the ID of the risk domain that constitutes a rejection of the request
  REJECT_DOMAIN = :d3

  OBLIGATIONS = [
                  :system_log_request,
                  :user_send_email,
                  :fill_form,
                  :none
                 ]
  
  MITIGATION_STRATEGIES = { 
    ms1: 
    { 
      d1: :none,
      d2: :user_send_email,
      d3: :none,
    },
    ms2: 
    { 
      d1: :none,
      d2: :user_send_email,
      d3: :none,
    },
    ms3: 
    { 
      d1: :none,
      d2: :user_send_email,
      d3: :none,
    },
  }
  
  SENSITIVITY_TO_STRATEGIES = {
    high: :ms1,
    med: :ms2,
    low: :ms3
  }


  # PARAMETERS SPECIFIC TO RAAC
  # Probability of one of an agent's obligations hitting a deadline in
  # any time step - thus permanent decrease of risk budget (easier
  # than implementing TTL... although might be more rigorous)
  OBLIGATION_TIMEOUT_PROB = 0.1
  INITIAL_BUDGET = 15
  BUDGET_DECREMENT = 1

  # PARAMETERS SPECIFIC TO TRAAC

  ST_PRIOR = 0
  OT_PRIOR = 1

  # we will use 'g' to mean good (trustworthy) and b to mean bad, for
  # sharing trust and obligation trust respectively
  TYPES = {
    gg: { sharing: 0.8, obligation: 0.5, count: 10 },
    gb: { sharing: 0.8, obligation: 0.1, count: 10 },
    bg: { sharing: 0.2, obligation: 0.5, count: 10 },
    bb: { sharing: 0.2, obligation: 0.1, count: 10 }
  }

  # for the moment, just two groups - mainly good (mg) and mainly bad
  # (mb) this structure specifies the probability, for a given
  # profile, the probability of an agent from that profile belonging
  # to a given group note: a requester can be in more than one group

  GROUPS = {
    mg: { gg: 0.9, gb: 0.8, bg: 0.1, bb: 0.2 },
    mb: { gg: 0.1, gb: 0.2, bg: 0.9, bb: 0.8 },
  } 

end
