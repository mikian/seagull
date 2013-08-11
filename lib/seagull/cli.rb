require 'thor'
require 'hashie/mash'
require 'yaml'

module Seagull
  class CLI < Thor
    attr_reader :configuration
    
    def initialize(*args)
      super
      
      @configuration = Hashie::Mash.new
      if File.exists?('.seagull')
        @configuration.deep_merge!(YAML.load_file('.seagull'))
      end
    end
    
    desc "debug", "Opens debug console"
    def debug
      require 'pry'
      require 'seagull/versionomy/format_definitions/apple'
      
      version = Versionomy.parse('1A1a', :apple)
      binding.pry
    end
  end
end

require 'seagull/tasks/config'
require 'seagull/tasks/version'
