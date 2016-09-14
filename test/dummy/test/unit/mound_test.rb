# encoding: utf-8

# Copyright (c) 2012-2016 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's {PROJECT TITLE}.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/{REPO-NAME}

require 'test_helper'

class RablTest < ActiveSupport::TestCase

  def setup
    
    ds = Mound::Deposit.new(:file => File.join(Rails.root.to_s, 'data', 'potpourri.yml'),
    
                  :special_columns => ['code'],
                  :delete_all => false,
                  :cache_enabled => true,
                  :debug => 9,
                  :search_columns => { :code => true, :mnemonic => true, :label => true, :name => true },
                  :guaranteed_non_self_referencing => true
                 )

    ds.scoop
    
  end

  test 'Get Diacritical Name' do
    
    vehicles = Vehicle.where({:model => 'Híjole Fríjoles'})

    # assert_equal 1, vehicles.size, "Did not find a vehicle with a model with diacriticals"
    
  end
  
end
