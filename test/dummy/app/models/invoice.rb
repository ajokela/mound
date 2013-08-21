class Invoice < ActiveRecord::Base
  belongs_to :invoice_type
  # attr_accessible :description, :price
  has_many :invoice_line_items
end
