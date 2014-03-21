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
        yield @configuration.deploy
      end

      def prepare
        puts "Nothing to prepare!"
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

