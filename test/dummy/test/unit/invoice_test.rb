require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "should be two invoices" do
    inv = Invoice.all

    assert_equal 2, inv.size, "Wrong number of invoices"
  end

  test "should be two line items" do
    inv = Invoice.find_by_description('basic')
    items = inv.invoice_line_items

    assert_equal 2, items.size, "Wrong number of line items"
  end

end
