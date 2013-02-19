class CreateVehicles < ActiveRecord::Migration
  def change
    create_table :vehicles do |t|
      t.string     :make
      t.string     :model
      t.integer    :year
      t.integer    :vehicle_type_id
      t.timestamps
    end
  end
end
