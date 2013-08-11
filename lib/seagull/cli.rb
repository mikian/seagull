require 'thor'
# require 'seagull/config'

module Seagull
  class CLI < Thor
    def initialize(*args)
      super
      
      # @config = Seagull::Config.instance      
    end
    
    desc "debug", "Opens debug console"
    def debug
      require 'pry'

      binding.pry
    end
  end
end

# 
require 'seagull/tasks/config'
require 'seagull/tasks/version'

module Seagull
  class CLI
    register(Seagull::Tasks::Config,  'config',  'config <command>',  'Manage and display configuration settings')
    register(Seagull::Tasks::Version, 'version', 'version <command>', 'Version release tasks')
  end
end
