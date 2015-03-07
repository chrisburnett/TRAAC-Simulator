require_relative 'sl_trust'
require_relative 'traac'

# this class models the GTRAAC behaviour by implementing the
# extensions for group trust assessment, update and obligations. It
# adds additional methods to deal with the cases where we can't use an
# individual trust assessment
class GtraacSTOT < TraacSTOT
end
