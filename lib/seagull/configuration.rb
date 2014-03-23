require 'app_conf'
require 'seagull/deployment_strategies'

module Seagull
  class Configuration < AppConf
    def initialize(defaults = {})
      super()

      # Set defaults
      from_hash({
        :configuration   => {:debug => 'Debug', :beta => 'AdHoc', :release => 'Release'},
        :build_dir       => 'build',
        :auto_archive    => true,
        :changelog_file  => File.expand_path('CHANGELOG.md'),
        :archive_path    => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :ipa_path        => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :dsym_path       => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :xcpretty        => true,
        :xctool_path     => "xctool",
        :xcodebuild_path => "xcodebuild",
        :workspace_path  => nil,
        :scheme          => nil,
        :app_name        => nil,
        :arch            => nil,
        :skip_clean      => false,
        :verbose         => false,
        :dry_run         => false,
        
        :deploy                => {
          :release_notes_items => 5,
        },
        :release_type          => :beta,
        :deployment_strategies => {},
      })
      
      self.load('.seagull.yml') if File.exists?(".seagull.yml")
      self.from_hash(defaults)
    end
    
    # Configuration
    def deployment(release_type, strategy_name, &block)
      if DeploymentStrategies.valid_strategy?(strategy_name.to_sym)
        deployment_strategy = DeploymentStrategies.build(strategy_name, self)

        self.deployment_strategies.send("#{release_type}=", deployment_strategy)
        self.deployment_strategies.send("#{release_type}").configure(&block)
      else
        raise "Unknown deployment strategy '#{strategy_name}'."
      end
    end

    def deployment_strategy(type)
      self.active_release_type = type
      self.deployment_strategies.send(type)
    end
    
    # Accessors
    def archive_name
      app_name || target || scheme
    end
    
    def archive_file_name(override = {})
      "#{archive_name}-#{marketing_version}-#{version}_#{configuration.send(override.fetch(:release_type, release_type))}.xcarchive"
    end
    
    def archive_full_path(type)
      File.join(archive_path, archive_file_name(release_type: type))
    end
    
    def ipa_name
      app_name || target || scheme
    end
    
    def ipa_file_name(override = {})
      "#{archive_name}-#{full_version}_#{configuration.send(override.fetch(:release_type, release_type))}.ipa"
    end
    
    def ipa_full_path(type)
      File.join(ipa_path, ipa_file_name(release_type: type))
    end
    
    def dsym_file_name(override = {})
      "#{archive_name}-#{full_version}_#{configuration.send(override.fetch(:release_type, release_type))}.dSYM.zip"
    end
    
    def dsym_full_path(type)
      File.join(dsym_path, dsym_file_name(release_type: type))
    end
    
    def version_data
      @version_data ||= begin
        vers    = %x{agvtool vers -terse|tail -1}.strip
        mvers   = %x{agvtool mvers -terse1|tail -1}.strip
        {marketing: mvers, version: vers}
      end
    end
    
    def reload_version!
      @version = nil; version_data
    end
    
    def marketing_version
      version_data[:marketing]
    end
    
    def version
      version_data[:version]
    end
    
    def full_version
      "#{marketing_version}.#{version}"
    end
    
    def version_tag
      "v#{full_version}"
    end
    
    def build_arguments(override = {})
      args = {}
      if workspace
        args[:workspace]     = "#{workspace}.xcworkspace"
        args[:scheme]        = scheme
      else
        args[:target]  = target
        args[:project] = project_file_path if project_file_path
      end

      args[:configuration] = configuration.send(release_type)
      args[:arch]          = arch unless arch.nil?
      
      args.merge!(override)
      
      args.collect{|k,v| "-#{k} #{Shellwords.escape(v)}"}
    end
  end
end
