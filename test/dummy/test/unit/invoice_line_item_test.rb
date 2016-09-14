# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

require 'test_helper'

class InvoiceLineItemTest < ActiveSupport::TestCase

  #test "invoice two should have two line items" do
  #  inv = Invoice.find_by_description('with child items')
  #  items = inv.invoice_line_items
  #  assert_equal 4, items.size, "Wrong number of line items"
  #end

  #test "invoice two should have parent/child line items" do
  #  inv_item = InvoiceLineItem.find_by_description('My Parent Item')
  #  children = inv_item.children
  #  assert_equal 3, children.size, "Wrong number of child line items"
  #end

end
