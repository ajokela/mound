class CreateInvoiceLineItems < ActiveRecord::Migration
  def change
    create_table :invoice_line_items do |t|
      t.string :description
      t.references :invoice
      t.integer :parent_id, :default => nil
      t.timestamps
    end
    add_index :invoice_line_items, :invoice_id
  end
end
