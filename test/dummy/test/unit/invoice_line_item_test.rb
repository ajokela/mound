require 'test_helper'

class InvoiceLineItemTest < ActiveSupport::TestCase

  test "invoice two should have two line items" do
    inv = Invoice.find_by_description('with child items')
    items = inv.invoice_line_items
    assert_equal 4, items.size, "Wrong number of line items"
  end

  test "invoice two should have parent/child line items" do
    inv_item = InvoiceLineItem.find_by_description('My Parent Item')
    children = inv_item.children
    assert_equal 3, children.size, "Wrong number of child line items"

  end


end
