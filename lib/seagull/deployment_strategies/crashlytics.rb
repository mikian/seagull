require 'tempfile'
require 'json'
require 'launchy'

module Seagull
  module DeploymentStrategies
    class Crashlytics < DeploymentStrategy

      # Nothing to prepare
      def prepare
        unless @configuration.deploy.crashlytics_location
          if dir = ['./', 'Pods/CrashlyticsFramework'].find{|d| ::File.directory?("#{d}/Crashlytics.framework")}
            @configuration.deploy.crashlytics_location = "#{dir}/Crashlytics.framework"
          end
        end
        raise "Please provide Crashlytics location" unless ::File.directory?(@configuration.deploy.crashlytics_location)
      end

      def deploy
        cmd = []
        cmd <<"#{@configuration.deploy.crashlytics_location}/submit"
        cmd << @configuration.deploy.api_key
        cmd << @configuration.deploy.build_secret
        cmd << "-ipaPath #{Shellwords.escape(@configuration.ipa_full_path(@configuration.active_release_type))}"

        system(cmd.join(' '))
      end

    private
    end
  end
end
