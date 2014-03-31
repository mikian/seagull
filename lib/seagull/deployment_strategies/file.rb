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
        # Make sure destionation directory exists
        unless ::File.directory?(@configuration.deploy.path)
          puts "Creating #{@configuration.deploy.path}"
          FileUtils.mkpath(@configuration.deploy.path)
        end
        
        # Copy xcarchive
        Dir.chdir(@configuration.archive_path) do
          deploy_path = ::File.join(@configuration.deploy.path, @configuration.archive_file_name(release_type: @configuration.active_release_type) + ".zip")
          FileUtils.rm deploy_path if ::File.exists?(deploy_path)
          puts "Creating XCArchive for deployment..."
          system("/usr/bin/zip --quiet --symlinks --recurse-paths #{Shellwords.escape(deploy_path)} #{Shellwords.escape(@configuration.archive_file_name(release_type: @configuration.active_release_type))}")
        end
        
        [
          @configuration.ipa_full_path(@configuration.active_release_type),
          @configuration.dsym_full_path(@configuration.active_release_type),
        ].each do |f|
          puts "Copying #{::File.basename(f)} for deployment..."
          FileUtils.cp_r f, @configuration.deploy.path
        end
        
        puts "Deployed to #{@configuration.deploy.path}/#{@configuration.archive_file_name(release_type: @configuration.active_release_type)}"
      end
      
      private
    end
  end
end
