# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

class CreateInvoiceLineItems < ActiveRecord::Migration
  def change
    create_table :invoice_line_items do |t|
      t.string     :name
      t.string     :description
      t.references :invoice
      t.references :vehicle, :default => nil
      t.integer    :parent_id, :default => nil
      t.timestamps
    end
    
    add_index :invoice_line_items, :invoice_id
    add_index :invoice_line_items, :parent_id
    
  end
end
