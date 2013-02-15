class InvoiceLineItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :parent, :class_name => "InvoiceLineItem", :foreign_key => "parent_id"
  has_many :children, :class_name => "InvoiceLineItem", :foreign_key => "parent_id"
  belongs_to :vehicle

  attr_accessible :description

end
