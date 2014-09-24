# encoding: utf-8
#######################################################################################################################
#                                              ####     #    ####   #
#                                              #   #   # #   #   #  #
#                                              ####   #   #  ####   #
#                                              # #    #####  #   #  #
#                                              #  ##  #   #  ####   #####
#######################################################################################################################
#
#   Ruby Abstract Bulk Loader
#
#######################################################################################################################
#
# Copyright (c) 2012, 2013, REGENTS OF THE UNIVERSITY OF MINNESOTA
# All rights reserved.
# Redistribution and use in source and binary forms, with or without modification, are permitted
# provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this list of conditions and
#   the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
#   the following disclaimer in the documentation and/or other materials provided with the
#   distribution.
# * Neither the name of the University of Minnesota nor the names of its contributors may be used to
#   endorse or promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY OF MINNESOTA ''AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE UNIVERSITY OF MINNESOTA BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#######################################################################################################################

require 'thread'
require 'rainbow'
require 'mound/acolyte'
require 'mound/string_ext'
require 'mound/lumber_jack'

#########
#
#  Mound
#
#  A "Mound" object requires a hash of options passed the call to "new"
#
#    :file => "relative path to the data file in a Mound-DSL-YAML-format"
#    :delete_all => true/false to delete all existing records before loading
#    :search_columns => a hash of symbols specifying valid column names to search for matching record columns
#
#                       This is representative of any column in your entire dataset that may be used for matching
#                       a referenced object.
#
#                       Example:
#
#                       Table: hotdogs
#
#                       id  |  meat_type_id  |  age  | created_at | updated_at
#                     ------+----------------+-------+------------+-----------
#                        1  |        1       |   3   |  *time*    |  *time*
#
#
#                       Table: meat_types
#
#                       id  |    meat   | created_at | updated_at
#                     ------+-----------+------------+------------
#                        1  |  mystery  |  *time*    |  *time*
#                    
#
#                      Assume that meat_types was loaded in first with a structure like:
#
#                      meat_types:
#                        - 
#                          meat: mystery
#
#                      Then later in the data file, you have a hotdog object specified like this:
#
#                      hotdogs:
#                        -
#                          age: 3
#                          meat_type_id: "mystery"
#
#                      your :search_columns hash would look like => {:meat => true}
#
#    :special_search_column_logic => by default, it is a simple lambda that returns true or false based on certain conditions
#
#                                    It takes the form:
#
#                                    lambda { |k, column_type, special_column, val, ar|  }
# 
#                                    k              = a single key obtained from a keys.keep_if {|k| lambda_gets_called_here }
#                                    column_type    = ActiveRecord->columns[:single_column]->type
#                                    special_column = one of the columns listed in option hash ":special_columns"
#                                    val            = individual value from an item/entry in the data file
#                                    obj            = an active record model object
#
#    :special_columns => hash of columns that may have different types in different ActiveModels
#                        For example, in TerraPop, one table has "code" as type integer, while another
#                        table has "code" as a string
#    :dry_run => if true, will rollback at the end. All data still is parsed and sent to the database,
#                        but the transaction isn't committed.
#

module Mound

  class Deposit

    attr_accessor :data, :objects, :exclude_columns, :search_columns, :special_search_column_logic, :special_columns
    attr_accessor :issues, :options, :debug, :dry_run, :cache_enabled, :transaction_enable

    VALID_OPERS = {:or => true, :and => true}
    SPECIAL_KEYS = {'_config' => true, 'post_build' => true}

    def initialize(*options)
      @@mutex = Mutex.new unless defined? @@mutex
      
      self.options = _config(options)

      preloaded_data = {}

      Mound::Utilities.wait_spinner {
        self.data = File.open(self.options[:file], 'r:UTF-8'){|f| YAML.load_stream(f) }.first
      }

      path = File.dirname(File.expand_path(self.options[:file]))

      SPECIAL_KEYS.each do |key, val|
        unless self.data.nil?
          if self.data.include? key
            if key == '_config'
              if self.data[key].class == Hash
                if self.data[key]['include_before'].class == Array
                  self.data[key]['include_before'].each do |file|
                  
                    yaml = File.open(File.join(path, file), 'r:UTF-8') {|f| YAML.load_stream(f)}.first
                  
                    preloaded_data.merge!(yaml)
                  end
                end
              end
            end
          end
        end
      end

      preloaded_data.merge!(self.data) unless self.data.nil?
      self.data = preloaded_data

      SPECIAL_KEYS.each do |key, val|
        unless self.data.nil?
          if self.data.include? key
            if key == '_config'
              if self.data[key].class == Hash
                if self.data[key]['include_after'].class == Array
                  self.data[key]['include_after'].each do |file|
                  
                    yaml = File.open(File.join(path, file), 'r:UTF-8') {|f| YAML.load_stream(f)}.first
                    self.data.merge!(yaml)
                  
                  end
                end
              end
            end
          end
        end
      end

      # open wide - this will generate a LOT of SQL output if enabled.

      ActiveRecord::Base.logger = Logger.new(STDOUT) if self.debug > 3

      $stderr.puts "data:\n\n#{self.data}\n\n" if self.debug > 3

    end

    def dump
      self.data
    end

    def scoop

      extend Rails.application.routes.url_helpers
      extend Rails.application.routes.mounted_helpers

      $stderr.puts "Database Configuration Information:\n\n#{ActiveRecord::Base.connection_config.inspect}\n\n" if self.debug > 1

      ActiveRecord::Base.connection.enable_query_cache! if self.cache_enabled

      Mound::Database::Transaction.block(self.transaction_enable) do

        $stderr.puts '' if self.debug > 1

        data.each do |key, dat|

          unless SPECIAL_KEYS.include? key

            obj = nil

            begin
              
              name = key.singularize.camelize
              $stderr.print "     + Working on #{name}".widthize(48) + "(#{dat.count} objects)  ".color(:yellow) if self.debug > 1

              # Get the class object for the class named 'name'.
              obj = _constantize(name)

            rescue Exception => e
              $stderr.puts "#{e}" if self.debug > 1
            end

            Mound::Utilities.wait_spinner(self.debug) {
              _load_data(dat, obj)
            }

            $stderr.puts '' if self.debug > 1

          end

        end

        raise ActiveRecord::Rollback if self.dry_run
      end # commit the transaction assuming it all went in correctly.

    end

    private

    # our own private constantize
    def _constantize(class_name)
      unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ class_name
        raise NameError, "#{class_name.inspect} is not a valid constant name!"
      end
      
      @@mutex.synchronize do
        Object.module_eval("::#{$1}", __FILE__, __LINE__)
      end
      
    end

    # load all the records for one entity type.
    # if requires_extra_work is false, they can be inserted directly.
    # If it's true, then call _load_single_instance which can look up the appropriate foreign keys and do the insert.
    def _load_data(dat, obj)
      $stderr.puts(__LINE__.to_s + ' ' + "Creating a new Cache for instances of #{obj}") if self.debug > 1
      cache = ActiveSupport::Cache::MemoryStore.new()

      $stderr.puts "Data for instances of #{obj}: \n\n" + dat.inspect + "\n\n" if self.debug > 3

      dat.each do |row|
        ar = obj.new
        _load_single_instance(ar, row, cache)
      end

    end

    # Load a single record for one entity type.
    # dat is a Hash of the properties for this entity.
    # Keep the result of foreign key lookups in a cache, to minimize redundant database hits.
    def _load_single_instance(record_obj, dat, cache)

      dat.each do |k, v|
        key = k.downcase
        do_not_send = false

        $stderr.puts(__LINE__.to_s + ' ' + "TRACE: _load_single_instance top: key:#{key}, v:#{v}") if self.debug > 2

        if key.match /_id$/
          # we need to go find a single foreign key value. Cache it if we can.
          if self.cache_enabled & cache.exist?(v)
            $stderr.puts(__LINE__.to_s + ' ' + "Found #{key}:#{v} in the cache") if self.debug > 2
            resolved_val = cache.read(v)
          else
            # TODO - if record_obj.association(:k).reflection.options(:class_name) is not null, then we need to use that as the class name for doing the lookup.
            k_sym = k.sub(/_id$/, '').intern
            # check to make sure that there's actually an AR association in place before trying to resolve it.

            $stderr.puts __LINE__.to_s + " k_sym => #{k_sym.to_s} - #{v.inspect} | #{v.class}" if self.debug > 2

            foreign_table_assoc = record_obj.class.reflect_on_association(k_sym)

            if foreign_table_assoc.nil?
              $stderr.puts(__LINE__.to_s + ' ' + "WARN: #{key} doesn't have a matching association - are you missing a has_many or belongs_to in #{record_obj.class}?")
              foreign_table = nil
            else
              foreign_table = record_obj.association(k_sym).reflection.options[:class_name]
            end

            if foreign_table.nil?
              $stderr.puts(__LINE__.to_s + ' ' + "TRACE: foreign_table is nil") if self.debug > 4
              resolved_val = _resolve_ids(key, v)
            else
              $stderr.puts(__LINE__.to_s + ' ' + "TRACE: #{key} points to foreign key #{foreign_table}") if self.debug > 2
              foreign_table_id = foreign_table.underscore + '_id'
              $stderr.puts(__LINE__.to_s + ' ' + "TRACE: Trying to resolve #{key} as if it were #{foreign_table_id}") if self.debug > 1
              resolved_val = _resolve_ids(foreign_table_id, v)
              $stderr.puts(__LINE__.to_s + ' ' + "TRACE: Found #{resolved_val}.") if self.debug > 2
            end
            cache.write(v, resolved_val) if self.cache_enabled
          end
        elsif key.match /_ids$/
          # Look for has_many_and_belongs_to_many relationships
          key_stub = key.sub(/_ids$/, '')
          to_many_key = key_stub.singularize.camelize
          $stderr.puts(__LINE__.to_s + ' ' + "TRACE: k: #{to_many_key}, v: #{v}") if self.debug > 3

          # get the subkeys for each element of the value
          if v.class == Array
            subkeys = v.collect { |subv| _resolve_ids(to_many_key, subv) }
            $stderr.puts(__LINE__.to_s + ' ' + "TRACE: subkeys for #{to_many_key} are: #{subkeys}") if self.debug > 3
          end

          # set up state for the record_obj.send call below.
          # the key from the yaml file is actually correct to begin with.
          # given a key of agg_data_var_group_ids, the collection name will be agg_data_var_groups
          # and the method to set the collection using explicit primary ids is agg_data_var_group_ids
          resolved_val = subkeys

        elsif key.match /^parent$/ or key.match /area_reference_variable$/
          unless v.nil?
            # pass in the class of record_obj - we just need a clean/fresh class object
            # because we are dealing with a 'parent' record, we just need to use the same
            # class type - because we need to use class methods to locate the id of the parent
            # of this record.  (I think...) -acj
            resolved_val = _resolve_ids(key, v, 'OR', record_obj.class)
            key = key + '_id'
          end
        
        elsif key.match /^_all$/

          # we are going to update all items

          if v.class == Array

            all = record_obj.class.where({})

            v.each do |items|
              if items.class == Hash
                all.each do |single_obj|
                  _load_single_instance(single_obj, items, cache)
                end
              end
            end

          end

          do_not_send = true

        else
          resolved_val = v
        end

        # now that we've got the key and value for this field, set it on the object.
        $stderr.puts(__LINE__.to_s + ' ' + "TRACE: setting #{key} to: #{resolved_val}") if self.debug > 3

        unless do_not_send
          record_obj.send(key + '=', resolved_val)
        else
          $stderr.puts(__LINE__.to_s + ' ' + "TRACE: do_not_send is true - not setting #{key} to '#{resolved_val}'") if self.debug > 3
        end

      end

      # after processing all the elements for this object in the yaml file, save the object.
      
      $stderr.puts(__LINE__.to_s + ' ' + "TRACE: record_obj.changed? is #{record_obj.changed?}") if self.debug > 3
      $stderr.puts(__LINE__.to_s + ' ' + "#{record_obj.class.to_s} inspection: \n\n#{record_obj.inspect}") if self.debug > 3
        
      record_obj.save if record_obj.changed?
    end

    # build_clause_elements is a helper method used by resolve_ids.
    # Given an array of query_keys and an array of query_values, it generates the cross-product of the two arrays
    # suitable for use in an ARel query.
    # obj_table is the arel_table underlying an Active Record model object.
    def build_clause_elements(query_keys, query_vals, obj_table)
      result = []
      unless query_keys.empty? || query_vals.empty?
        columns = query_keys.map { |key| obj_table[key.to_sym] }
        column_combos = columns.permutation(query_vals.size).to_a

        result = column_combos.map { |this_combo|
          combo_with_keys = this_combo.zip(query_vals)
          # pair up each key column with a value
          clause_elements = combo_with_keys.map { |field| field[0].eq(field[1]) }
          # and make a WHERE clause component.
          clause_elements.inject { |memo, item| memo.and(item) }
        }
      end
      result
    end

    def resolve_compound_keys(key, obj, val)
      
      $stderr.puts(__LINE__.to_s + ' ' + "TRACE: resolve_compound_keys -------- \n\n\n\n") if self.debug > 4

      $stderr.puts(__LINE__.to_s + ' ' + "key: #{key.to_s}") if self.debug > 4
      $stderr.puts(__LINE__.to_s + ' ' + "obj: #{obj.to_s}") if self.debug > 4
      $stderr.puts(__LINE__.to_s + ' ' + "val: #{val.to_s}") if self.debug > 4
      
      string_vals = []
      integer_vals = []
      keyed_vals = {}

      # split the values apart based on data type
      val.each { |item|
        if item.is_a?(String)
          # If the string can be interpreted as an integer, keep it in the integer_vals array.
          # If not, put it in the string_vals array.
          string_vals << item
        elsif item.is_a?(Integer)
          integer_vals << item.to_i
        elsif item.class == Hash
          # If it's a hash, then it's a subkey; something like the invoice_type_id entry below.
          #
          # invoice_line_items:
          # -
          # name: kid1
          # description: My Subitem1
          # invoice_id:
          #     - 'two'
          #     - 'with child items'
          #     - invoice_type_id: 'credit'
          # parent: three
          #
          # If that's the case, go look up the subkey now.

          item.each { |item_k, item_v|
            $stderr.puts "\n\n====> item_k: #{item_k} | item_v: #{item_v}\n\n" if self.debug > 4
            returned_id = _resolve_ids(item_k, item_v)
            keyed_vals[item_k] = returned_id
            $stderr.puts "====> item_ret: #{returned_id}" if self.debug > 4
          }

        end
      }

      $stderr.puts(__LINE__.to_s + " TRACE: string_vals: #{string_vals.to_s}") if self.debug > 4
      $stderr.puts(__LINE__.to_s + " TRACE: integer_vals: #{integer_vals.to_s}") if self.debug > 4

      ar = obj.new

      potential_key_columns = ar.attributes.keys.keep_if { |column| column.match(exclude_columns).nil? }

      # find the potential_key_columns that are typed as integer or as string,
      # except for the primary key column (id) itself and other integer foreign keys (which should end with _id)
      # Note that we can't preclude all columns that end in _id, because we want to keep columns like
      # sample_id on terrapop_samples, which is a varchar.
      integer_keys = potential_key_columns.find_all { |pk| !(pk == 'id' or pk.end_with?('_id')) and obj.columns.find { |c| c.name == pk }.type == :integer }
      string_keys = potential_key_columns.find_all { |pk| obj.columns.find { |c| c.name == pk }.type == :string }

      # build up permutations of potential key matches We assume that there are more potential columns than there are values given.
      obj_table = obj.arel_table

      # only do integer-flavored lookups if there are both integer keys and integer values.
      arel_int_clauses = build_clause_elements(integer_keys, integer_vals, obj_table)

      # only do string-flavored lookups if there are both string keys and string values.
      arel_str_clauses = build_clause_elements(string_keys, string_vals, obj_table)

      # now that we've got the subclauses built up, we need to build up a series of clauses of the form:
      # ((str_key1 = strval1 AND str_key2 = strval2 AND intkey1 = intval1 AND intkey2=intval2) OR
      # (str_key1 = strval1 AND str_key2 = strval2 AND intkey1 = intval2 AND intkey2=intval1) OR
      # (str_key2 = strval1 AND str_key1 = strval2 AND intkey1 = intval1 AND intkey2=intval2) OR
      # (str_key2 = strval1 AND str_key1 = strval2 AND intkey1 = intval2 AND intkey2=intval1))
      # AND foreign_key_id = keyval1

      $stderr.puts __LINE__.to_s + " TRACE: arel_str_clauses: #{arel_str_clauses.inspect}" if self.debug > 10

      key_clause = nil
      final_arel_clauses = nil
      arel_clause_groups = []
      ret = []

      $stderr.puts __LINE__.to_s + " TRACE: keyed_vals: #{keyed_vals.inspect}" if self.debug > 5

      unless keyed_vals.empty?
        clause_elements = keyed_vals.map { |k, v| obj_table[k.to_sym].eq(v) }
        key_clauses = clause_elements.inject { |memo, item| memo.and(item) }
        key_clause = Arel::Nodes::Grouping.new(key_clauses)
      end

      # build up the arel_clause_group structure based on whether we've got
      # str_clauses, int_clauses, or both.
      if arel_int_clauses.empty?
        unless arel_str_clauses.empty?
          # if we have strings but no ints, build up the final clause from the string clauses.
          arel_clause_groups = arel_str_clauses
        end
      else
        if arel_str_clauses.empty?
          # if we have ints but no strings, build up the final clause from the int clauses.
          arel_clause_groups = arel_int_clauses
        else
          # we've got both, so combine them to build up the final clause.
          combined_clauses = arel_str_clauses.product(arel_int_clauses)
          arel_clause_groups = combined_clauses.map { |clause| clause.inject { |memo, item| memo.and(item) } }
        end
      end

      $stderr.puts __LINE__.to_s + " TRACE: arel_clause_groups: #{arel_clause_groups.inspect}" if self.debug > 10

      

      # four distinct possibilities:
      # arel clause groups could be empty or not
      # key_clause could be empty or not
      
      if arel_clause_groups.empty?
        
        $stderr.puts __LINE__.to_s + " TRACE: arel_clause_groups is empty" if self.debug > 5
        
        if key_clause.nil?
          final_arel_clauses = nil
        else
          final_arel_clauses = key_clause
        end
      else
        # arel_clause_groups contains an array of the conjunction terms for the where clause (a bunch of AND expressions),
        # and we want to OR them all together for the final query.
        # in order to get them in the form
        # (clause group 1) OR (clause group 2) OR (clause group 3...)
        # they first need to be wrapped in Arel::Nodes::Grouping instances. Then they can be combined using OR statements.
        
        $stderr.puts __LINE__.to_s + " TRACE: arel_clause_groups is NOT empty" if self.debug > 5
        
        grouped_clause_groups = arel_clause_groups.map { |g| Arel::Nodes::Grouping.new(g) }
        
        $stderr.puts __LINE__.to_s + " TRACE: generated grouped_clause_groups.size: #{grouped_clause_groups.size}" if self.debug > 5
        
        arel_clauses = grouped_clause_groups.inject { |memo, item| memo.or(item) }
        
        if key_clause.nil?
          final_arel_clauses = arel_clauses
        else
          final_arel_clauses = arel_clauses.and(key_clause)
        end
      end
      
      # $stderr.puts __LINE__.to_s + " TRACE: final_arel_clauses: #{final_arel_clauses.inspect}" if self.debug > 5

      unless final_arel_clauses.nil?
        arel_query = obj.where(final_arel_clauses)
        arel_query_string = arel_query.to_sql
        ret = arel_query.to_a
      end

      unless ret.size == 1
        raise "ERROR: Attempting to locate a single #{obj.class} returned #{ret.size}, should be only 1\n\n" +
              "Complete Information: key => '#{key}',\n string_keys => '#{string_keys.inspect}',\n integer_keys => '#{integer_keys.inspect}',\n val => '#{val.inspect}',\n obj => '#{obj.inspect}'\n sql => '#{arel_query_string}'\n ret => '#{ret.inspect}' ".color(:red).bright
      end

      # hand back the result of the query.
      ret
    end

    def _resolve_ids(key, val, bool_oper = 'OR', obj = nil)
      # We're looking for an object of type 'key' that has primary keys of 'val'. Val may be a hash, or it may be a value.
      $stderr.puts __LINE__.to_s + " TRACE: digging for Key: #{key.to_s}, Val: #{val.to_s}" if self.debug > 4

      unless VALID_OPERS.include? bool_oper.downcase.to_sym
        bool_oper = 'OR'
      end

      # if we weren't explicitly given a class object to instantiate, get the class now.
      if obj.nil?
        $stderr.puts __LINE__.to_s + " TRACE: obj passed into _resolve_ids is nil" if self.debug > 4
        class_name = key.sub(/_id$/, '').singularize.camelize
        obj = _constantize(class_name)
      end

      ######
      #
      #  If we have an Array, we need to see if it is an Array of Strings or an Array of Hashes
      #

      if val.class == Array
        
        $stderr.puts __LINE__.to_s + " TRACE: val is class 'Array'" if self.debug > 4

        contains = []

        val.each { |item|
          contains << item.class
        }

        vals = {}

        if contains.size == 1 and contains.first == Hash

          val.each do |v|

            v.each do |sub_key, sub_val|
              vals[sub_key] = _resolve_ids(sub_key, sub_val)
            end

          end

          $stderr.puts __LINE__.to_s + " TRACE: Complete Information: key => '#{key}', val => '#{val.inspect}', obj => '#{obj.inspect}'" if self.debug > 4

          return _resolve_ids(key, vals, 'AND') # vals

        else

          $stderr.puts __LINE__.to_s + " TRACE: Resolving Compound Keys for [key: #{key.to_s}] => #{obj.to_s} - [#{val.to_s}]" if self.debug > 4
          
          if contains.include? Array
            raise "An Array element was detected within a compound key; | Complete Information: key => '#{key}', val => '#{val.inspect}', obj => '#{obj.inspect}', contains => #{contains}"
          end

          ret = resolve_compound_keys(key, obj, val)

          return ret.first.id

        end

      else

        $stderr.puts __LINE__.to_s + " TRACE: val is not class 'Array'" if self.debug > 4
        
        if bool_oper.casecmp('and') == 0 and val.class == Hash

          val_obj = obj.where(val)

        else

          ar = obj.new
          keys = ar.attributes.keys.keep_if { |k| search_columns.include? k.to_sym }
          
          $stderr.puts  __LINE__.to_s + " TRACE: Active Record Model Inspection => #{ar.inspect}" if self.debug > 4

          if special_search_column_logic.class == Proc
            special_columns.each do |c|
              if ar.attributes.include? c

                keys = keys.keep_if { |k| 
                  $stderr.puts  __LINE__.to_s + " TRACE: #{ar.class}" if self.debug > 4
                  special_search_column_logic.call(k, ar.column_for_attribute(c).type, c, val, ar) 
                }

              end
            end
          end
          
          #vals = ([val.to_s] * keys.size)
          
          ###########
          # Arel Related Testing
          
          arel_relation = keys.map{|key| 
            obj.arel_table[key.to_sym].eq(val)
          }.inject{|result,item| result.or(item) }
          
          ###########

          # construct a WHERE clause to deal with looking up the foreign key requested in the call
          #where_str = keys.join(" = ? #{bool_oper} ") + ' = ?'

          val_obj = obj.where(arel_relation)
          
          $stderr.puts __LINE__.to_s + " TRACE: " + obj.where(arel_relation).to_sql + "\n\n" if self.debug > 4

        end

        unless val_obj.nil?

          if val_obj.count == 1
            val = val_obj.first.id
          else

            message = "ERROR:\n\n".color(:red).bright
            message << "The following query returned #{val_obj.count} records:\n\n"
            message << val_obj.to_sql
            message << "\n\n"

            raise message

          end


        else
          raise "val_obj is nil for #{where_str} on #{obj.to_s} with '#{vals}'"
        end

        val

      end

    end

    def _config(options)

      self.issues = []

      options = options[0] if options.size > 0

      if options[:debug]
        self.debug = options[:debug]
      else
        self.debug = 0
      end

      unless ENV['DEBUG'].nil?
        self.debug = ENV['DEBUG'].is_i? ? ENV['DEBUG'].to_i : 0
      end

      unless options.include? :file
        self.issues << '+ A YAML data file was not specified.'
      end

      if options[:objects] and options[:objects].class == Hash
        self.objects = options[:objects]
      elsif options[:objects] and options[:objects].class != Hash
        self.issues << '+ :objects is required to be of type Hash'
      else
        self.objects = {}
      end

      if options[:search_columns] and options[:search_columns].class == Hash
        self.search_columns = options[:search_columns]
      elsif options[:search_columns] and options[:search_columns].class != Hash
        self.issues << '+ :search_columns is required to be of type Hash'
      else
        self.search_columns = {}
      end

      if options[:special_search_column_logic]
        self.special_search_column_logic = options[:special_search_column_logic]
      else

        self.special_search_column_logic = lambda { |k, column_type, special_column, val, obj|
          if k.casecmp(special_column) == 0 and column_type != :string and val.to_s.is_i?
            true
          elsif k.casecmp(special_column) == 0 and column_type == :string
            true
          elsif k.casecmp(special_column) != 0
            true
          else
            false
          end
        }

      end

      if options[:exclude_columns]
        self.exclude_columns = options[:exclude_columns]
      else
        self.exclude_columns = /(^created_at$)|(^updated_at$)/
      end

      if options[:special_columns]
        self.special_columns = options[:special_columns]
      else
        self.special_columns = []
      end

      if self.issues.size > 0
        raise 'Error(s): ' + issues.join("\n")
      end

      if options[:cache_enabled]
        self.cache_enabled = options[:cache_enabled]
      else
        self.cache_enabled = false
      end

      if options[:dry_run]
        self.dry_run = options[:dry_run]
      else
        self.dry_run = false
      end

      unless ENV['TRANSACTION_ENABLE'].nil?
        self.transaction_enable = ENV['TRANSACTION_ENABLE'].is_bool? ? ENV['TRANSACTION_ENABLE'].to_bool : true
      end


      if self.dry_run
        $stderr.puts "\n\nDry Run Enabled\n\n".bright
      end

      options
    end

  end

end


