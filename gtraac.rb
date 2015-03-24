require_relative 'sl_trust'
require_relative 'traac'

# this class models the GTRAAC behaviour by implementing the
# extensions for group trust assessment, update and obligations. It
# adds additional methods to deal with the cases where we can't use an
# individual trust assessment
class GtraacSTOT < TraacSTOT

  # the gtraac model doesn't maintain any additional trust models over
  # the individual ones - this is because all group trust assessments
  # are computed (somehow!) from the individual assessments
  def initialize
    super
  end

  def compute_risk(request, ind_policy, grp_policy)
    # compute individual trust and group trust based on all evidence
    # we can get - group trust metric will be used as apriori (like
    # with stereotypes)
    grp_trust = compute_group_trust(request, grp_policy)
    
  end
  
  # compute the trust ratings for the group(s) being assessed
  def compute_group_trust(request, grp_policy)
    
    # the thing to address here is, you look at the other members of
    # the group being assessed, get the trust ratings for them, ???
    # and then come up with single rating.
    
  end

  # compute the risk of allowing an agent with some group memberships
  # to share some information
  def compute_group_risk(request, grp_policy)
  end

  

end
