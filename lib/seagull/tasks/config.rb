module Seagull
  module Tasks
    class Config < Thor
      def initialize(*args)
        super

        @config = Seagull::Config.instance
      end
      
      desc "print [KEY]", "Prints current config, with optionally filtering using key"
      def print(key = nil)
        cfgs = _build_config_array(@config.to_hash)
      
        cfgs.select!{|cfg| cfg.first[/#{key}/] } if key

        print_table(cfgs)
      end
    
      desc "set KEY VALUE", 'Sets given key (as path) to given value'
      def set(key, value)
        _value = case value
        when 'true'         then true
        when 'yes'          then true
        when 'false'        then false
        when 'no'           then false
        when /^[0-9]+$/     then value.to_i
        when /^:[a-zA-Z]+$/ then value[1..-1].to_sym
        else                value
        end

        keypath = key.split('/')
        cfg = Hash[keypath.pop, _value]
        while k = keypath.pop
          cfg = Hash[k, cfg]
        end
        @config.deep_merge!(cfg)
      
        @config.save
        say_status "config", "#{key} set to #{_value}", :green
      end
    
      private
        def _build_config_array(cfg, prefix = '')
          cfgs = []
        
          cfg.each do |key, value|
            if value.kind_of?(Hash)
              cfgs += _build_config_array(value, "#{prefix}/#{key}")
            else
              cfgs << ["#{prefix}/#{key}", value]
            end
          end
          cfgs
        end
    end
  end
end
