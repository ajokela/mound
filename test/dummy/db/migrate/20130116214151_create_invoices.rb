# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.string     :name
      t.string     :description
      t.decimal    :price
      t.references :invoice_type
      t.references :shipping_state, :default => nil

      t.timestamps
    end
    add_index :invoices, :invoice_type_id
  end
end
