require 'vandamme'

module Seagull
  module DeploymentStrategies
    def self.valid_strategy?(strategy_name)
      strategies.keys.include?(strategy_name.to_sym)
    end

    def self.build(strategy_name, configuration)
      strategies[strategy_name.to_sym].new(configuration)
    end

    class DeploymentStrategy
      def initialize(configuration)
        @configuration = configuration

        if respond_to?(:extended_configuration_for_strategy)
          @configuration.instance_eval(&extended_configuration_for_strategy)
        end
      end

      def configure(&block)
        @configuration.deploy.from_hash(defaults)
        
        yield @configuration.deploy
      end
      
      def defaults
        {}
      end
      
      def prepare
        puts "Nothing to prepare!"
      end
      
      def deploy
        raise "NOT IMPLEMENTED"
      end
      
      def release_notes
        changelog = ::File.exists?(@configuration.changelog_file) ? ::File.read(@configuration.changelog_file) : ""

        parser = Vandamme::Parser.new(changelog: changelog, version_header_exp: '^\*\*?([\w\d\.-]+\.[\w\d\.-]+[a-zA-Z0-9])( \/ (\d{4}-\d{2}-\d{2}|\w+))?\*\*\n?[=-]*', format: 'markdown')
        changes = parser.parse
        
        changes.first(@configuration.deploy.release_notes_items).collect{|v, c| "**#{v}**\n\n#{c}" }.join("\n\n")
      end
    end

    private

    def self.strategies
      {:file => File, :hockeyapp => HockeyApp}
    end
  end
end

require 'seagull/deployment_strategies/file'
require 'seagull/deployment_strategies/hockey_app'

