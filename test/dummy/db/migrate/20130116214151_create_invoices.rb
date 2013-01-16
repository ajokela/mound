class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.string :description
      t.decimal :price
      t.references :invoice_type

      t.timestamps
    end
    add_index :invoices, :invoice_type_id
  end
end
