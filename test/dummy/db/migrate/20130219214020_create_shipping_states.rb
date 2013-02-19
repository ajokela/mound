class CreateShippingStates < ActiveRecord::Migration
  def change
    create_table :shipping_states do |t|
      t.string :name

      t.timestamps
    end
  end
end
