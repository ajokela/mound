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
