require 'test_helper'

class RablTest < ActiveSupport::TestCase
  test 'rabl is a module' do
    assert_kind_of Module, Rabl
  end
end
