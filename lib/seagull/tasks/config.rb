module Seagull
  class CLI
    class Config < CLI
      # include Thor::Actions
      
      desc "print", "Prints current config"
      def print(key = nil)
        cfgs = _build_config_array(configuration.to_hash)
        
        cfgs.select!{|cfg| cfg.first[/#{key}/] } if key

        print_table(cfgs)
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
    
    register(Config, 'config', 'config <command>', 'Manage and display configuration settings')
  end
end