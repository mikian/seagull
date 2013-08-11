require 'singleton'
require 'hashie/mash'
require 'yaml'

module Seagull
  class Config
    include Singleton
    
    def initialize
      @config = Hashie::Mash.new({
        config:  {file: '.seagull'},
        version: {file: 'VERSION.yml', format: :apple}
      })
      
      load
    end
    
    def load
      if File.exists?(@config.config.file)
        @config.deep_merge!(YAML.load_file(@config.config.file))
      end
    end
    
    def save
      File.open(@config.config.file, 'w') {|io| io.puts self.to_yaml }
    end
    
    def to_yaml
      @config.to_hash.to_yaml
    end
    
    # Proxy
    def method_missing(m, *args, &blk)
      @config.send(m, *args, &blk)
    end
    
    def respond_to?(m)
      @config.respond_to?(m)
    end
  end
end
