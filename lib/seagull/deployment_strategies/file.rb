module Seagull
  module DeploymentStrategies
    class File < DeploymentStrategy
      def extended_configuration_for_strategy
        proc do
          def generate_release_notes(&block)
            self.release_notes = block if block
          end
        end
      end

      def prepare
      end

      def deploy
        # Make sure destionation directoy exists
        FileUtils.mkpath(@configuration.deploy.path) unless ::File.directory?(@configuration.deploy.path)
        
        # Copy xcarchive
        Dir.chdir(@configuration.archive_path) do
          deploy_path = ::File.join(@configuration.deploy.path, @configuration.archive_file_name(release_type: @configuration.active_release_type) + ".zip")
          FileUtils.rm deploy_path if ::File.exists?(deploy_path)
          system("/usr/bin/zip --symlinks --recurse-paths #{Shellwords.escape(deploy_path)} #{Shellwords.escape(@configuration.archive_file_name(release_type: @configuration.active_release_type))}")
        end
        
        [
          @configuration.ipa_full_path(@configuration.active_release_type),
          @configuration.dsym_full_path(@configuration.active_release_type),
        ].each do |f|
          FileUtils.cp_r f, @configuration.deploy.path
        end
      end
      
      private
    end
  end
end
