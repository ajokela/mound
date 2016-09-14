# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

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
