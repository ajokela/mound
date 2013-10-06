# encoding: utf-8
require 'test_helper'

class RablTest < ActiveSupport::TestCase

  def setup
    
    ds = Mound::Deposit.new(:file => File.join(Rails.root.to_s, 'data', 'potpourri.yml'),
    
                  :special_columns => ['code'],
                  :delete_all => false,
                  :cache_enabled => true,
                  :debug => 9,
                  :search_columns => { :code => true, :mnemonic => true, :label => true, :name => true },
                 )

    ds.scoop
    
  end

  test 'Get Diacritical Name' do
    
    vehicles = Vehicle.where({:model => 'Híjole Fríjoles'})

    # assert_equal 1, vehicles.size, "Did not find a vehicle with a model with diacriticals"
    
  end
  
end
