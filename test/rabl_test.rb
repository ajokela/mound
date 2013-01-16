require 'test_helper'

class RablTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Rabl

    # make it break
    assert false
  end
end
