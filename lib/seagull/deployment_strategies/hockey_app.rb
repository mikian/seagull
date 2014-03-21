module Seagull
  module DeploymentStrategies
    class HockeyApp < DeploymentStrategy
      def extended_configuration_for_strategy
        proc do
          def generate_release_notes(&block)
            self.release_notes = block if block
          end
        end
      end
      
      def deploy
      end
      
      private
    end
  end
end
