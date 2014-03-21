require 'app_conf'
require 'seagull/deployment_strategies'

module Seagull
  class Configuration < AppConf
    def initialize(defaults = {})
      super()
      
      self.load('.seagull.yml') if File.exists?(".seagull.yml")
      self.from_hash(defaults)
      
      # Set defaults
      self.release_type = :beta
    end
    
    # Configuration
    def deployment(release_type, strategy_name, &block)
      if DeploymentStrategies.valid_strategy?(strategy_name.to_sym)
        self.deployment_strategy = DeploymentStrategies.build(strategy_name, self)
        self.deployment_strategy.configure(&block)
      else
        raise "Unknown deployment strategy '#{strategy_name}'."
      end
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
