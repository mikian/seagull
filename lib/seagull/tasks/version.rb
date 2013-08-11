require 'versionomy'
require 'seagull/versionomy/format_definitions/apple'

module Seagull
  class CLI
    class Version < CLI
      desc "print", "Prints current version"
      def print
        say_status "current", "0.25.1.1.2"
      end
      
    end
    
    register(Version, 'version', 'version <command>', 'Version release tasks')
  end
end