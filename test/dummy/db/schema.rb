# encoding: UTF-8
# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130219214020) do

  create_table "invoice_line_items", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "invoice_id"
    t.integer  "vehicle_id"
    t.integer  "parent_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "invoice_line_items", ["invoice_id"], :name => "index_invoice_line_items_on_invoice_id"
  add_index "invoice_line_items", ["parent_id"], :name => "index_invoice_line_items_on_parent_id"

  create_table "invoice_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "invoices", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.decimal  "price"
    t.integer  "invoice_type_id"
    t.integer  "shipping_state_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "invoices", ["invoice_type_id"], :name => "index_invoices_on_invoice_type_id"

  create_table "shipping_states", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "vehicle_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "vehicles", :force => true do |t|
    t.string   "make"
    t.string   "model"
    t.integer  "year"
    t.integer  "vehicle_type_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
