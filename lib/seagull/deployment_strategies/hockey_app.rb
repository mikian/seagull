require 'tempfile'
require 'json'
require 'launchy'

module Seagull
  module DeploymentStrategies
    class HockeyApp < DeploymentStrategy

      def defaults
        {
          :allow_download => true,
          :notify         => true,
          :mandatory      => false,
          :tags           => '',
        }
      end

      # Nothing to prepare
      def prepare
      end

      def deploy
        # Create response file
        response_file = Tempfile.new('seagull_deploy_hockey')
        payload = {
          status: @configuration.deploy.allow_download ? 2 : 1,
          notify: @configuration.deploy.notify ? 1 : 0,
          mandatory: @configuration.deploy.mandatory ? 1 : 0,
          tags: @configuration.deploy.tags,
          notes: release_notes,
          notes_type: 1,
          ipa: "@#{Shellwords.escape(@configuration.ipa_full_path(@configuration.active_release_type))}",
          dsym: "@#{Shellwords.escape(@configuration.dsym_full_path(@configuration.active_release_type))}",
          commit_sha: %x{git rev-parse HEAD}.strip,
          repository_url: %x{git remote -v|grep fetch|awk '{print $2;}'}.strip,
        }
        opts = payload.collect{|k,v| "-F #{k}=#{Shellwords.escape(v)}"}.join(" ")

        puts "Uploading to Hockeyapp... Please wait..."
        system("curl #{opts} -o #{response_file.path} -H 'X-HockeyAppToken: #{@configuration.deploy.token}' https://rink.hockeyapp.net/api/2/apps/#{@configuration.deploy.appid}/app_versions/upload")

        response_body = if response_file.size > 0
          response_file.read
        else
          "{}"
        end
        response = JSON.parse(response_body)
        if response['config_url']
          puts "Version page: #{response['config_url']}"
          Launchy.open(response['config_url'])
        else
          puts "FAILED to upload app"
        end
      ensure
        response_file.unlink
      end

    private
    end
  end
end
