class Vehicle < ActiveRecord::Base
  attr_accessible :make, :model, :year
  has_many :invoice_line_items
end
