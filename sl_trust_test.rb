require_relative 'sl_trust'
require 'test/unit'

class TestDirectSLTrustModel < Test::Unit::TestCase

  def setup
    @tm = DirectSLTrustModel.new()
  end
  
  def test_unknown_agent
    assert_equal(0.5, @tm.rating(:john))
  end

  def test_add_evidence
    @tm.add_evidence(:mike, true)
    assert_not_equal(0.5, @tm.rating(:mike)
  end

end
