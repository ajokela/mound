# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

class InvoiceLineItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :parent, :class_name => 'InvoiceLineItem', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'InvoiceLineItem', :foreign_key => 'parent_id'
  belongs_to :vehicle

  # attr_accessible :description

end
