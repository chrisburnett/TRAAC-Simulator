require_relative 'traac'
require_relative 'raac'

module Parameters

  TIME_STEPS = 100
  RUNS = 10
  
  # how many data owners to use and evaluate
  OWNER_COUNT = 60
  
  # experimental condition (RAAC classes)
  MODEL = TraacSTOnly

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
    d1: [0,0.2],
    d2: [0.2,0.8],
    d3: [0.8,1]
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
      d3: :system_log_request,
    },
    ms2: 
    { 
      d1: :none,
      d2: :user_send_email,
      d3: :system_log_request,
    },
    ms3: 
    { 
      d1: :none,
      d2: :user_send_email,
      d3: :system_log_request,
    },
  }
  
  SENSITIVITY_TO_STRATEGIES = {
    high: :ms1,
    med: :ms2,
    low: :ms3
  }

  SENSITIVITY_TO_LOSS = {
    high: 0.9,
    med: 0.5,
    low: 0.1
  }

  # PARAMETERS SPECIFIC TO RAAC
  INITIAL_BUDGET = 10
  BUDGET_DECREMENT = 3

  # PARAMETERS SPECIFIC TO TRAAC
  

  # we will use 'g' to mean good (trustworthy) and b to mean bad, for sharing trust and obligation trust respectively
  TYPES = {
    gg: { sharing: 0.8, obligation: 0.8, count: 6 },
    gb: { sharing: 0.3, obligation: 0.3, count: 6 },
    bg: { sharing: 0.3, obligation: 0.8, count: 6 },
    bb: { sharing: 0.3, obligation: 0.3, count: 6 }
  }
end
