require 'test_helper'

class InvoiceTypeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should be two" do
    all_types = InvoiceType.all
    assert_equal 2, all_types.size, "wrong number of invoice types"
  end
end
