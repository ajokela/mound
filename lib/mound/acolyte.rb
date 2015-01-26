module Mound
  
  module Database
    module Transaction
      
      def self.block(enable, &b)
      
        if enable
          ActiveRecord::Base.transaction do
            b.call
          end
        else
          b.call
        end
        
      end
      
    end
  end
  
  module Utilities
    
    def self.spin
      iter = true
      
      thread = Thread.new do
        while iter do
          sleep 1
        end
      end
      
      yield.tap {
        iter = false
        thread.join
      }
      
    end
    
    def self.wait_spinner( args = {} )
    
      defaults = {:fps=> 10, :enable => true, :debug => 0}
      
      if args.class == Hash
        args = defaults.merge(args)
      else
        args = defaults
      end
      
      unless args[:debug].nil?
        if args[:debug].to_s.to_i > 3
          args[:enable] = false
        end
      end
      
      unless ENV['DEBUG'].nil?
        if ENV['DEBUG'].to_i > 3
          args[:enable] = false
        end
      end
      
      unless ENV['DISABLE_SPINNER'].nil?
        args[:enable] = false
      end
      
      unless ENV['RAILS_ENV'].nil?
        if ENV['RAILS_ENV'].match(/test/)
          args[:enable] = false
        end
      end
      
      chars = %w[| / - \\]
      delay = 1.0/args[:fps].to_f
      iter = 0
      
      if args[:enable]
      
        spinner = Thread.new do
          while iter do  # Keep spinning until told otherwise
            if iter.is_a? Fixnum
              begin
                $stderr.print chars[(iter+=1) % chars.length]
                sleep delay
                $stderr.print "\b"
              rescue 
                
              end
            end
          end
        end
    
        yield.tap{       # After yielding to the block, save the return value
          iter = false   # Tell the thread to exit, cleaning up after itself…
          spinner.join   # …and wait for it to do so.
        }                # Use the block's return value as the method's
      
      else
        yield
      end
      
    end  
  end
  
end
