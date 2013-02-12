class String
  
  unless self.respond_to? 'widthize'
    def widthize(width = 64, filler = ' ')
      if self.size > width
        self.replace self.pretty_truncate(width - 3)
        self + (filler * ((width) - self.size))
      else
        self + (filler * (width - self.size))
      end
    end
  end

  unless self.respond_to? 'pretty_truncate'
    def pretty_truncate(char_limit)
      if self.size >= char_limit
        string = ""
        words = self.split(/ /)

        (0...words.count).each {|i|
          string << words[i] << " " unless (i+1) >= words.count or string.length >= char_limit
        }
        string.chop << "..."
      end
    end
  end
  
  unless self.respond_to? 'to_bool'
    def to_bool
      return true   if self == true   || self =~ (/(true|t|yes|y|1)$/i)
      return false  if self == false  || self =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("invalid value for boolean: \"#{self}\"")
    end
  end
  
  unless self.respond_to? 'is_bool?'
    def is_bool?
      !!(self == true || self =~ (/(true|t|yes|y|1)$/i) || self == false  || self =~ (/(false|f|no|n|0)$/i))
    end
  end
    
end