require 'singleton'
require 'seagull/config'
require 'versionomy'
require 'seagull/versionomy/format_definitions/apple'

module Seagull
  class Version
    include Singleton
    
    def initialize
      @config = Seagull::Config.instance
      
      @version = if File.exists?(@config.version.file)
        Versionomy.create(YAML.load_file(@config.version.file), @config.version.format)
      else
        Versionomy.create({}, @config.version.format)
      end
    end
    
    def peek(what)
      peek = case what
      when :release
        bump(:major)
      when :patch
        bump(:minor)
      when :update
        bump(:update)
      when :build
        bump(:build)
      else
        @version
      end
      
      peek.unparse
    end
    
    # Output marketing version
    def marketing
      case @config.version.format
      when :apple
        major, minor = @config.versions[@version.major].split('.')
        tiny         = @version.convert(:standard).tiny
        
        Versionomy.create(major: major, minor: minor, tiny: tiny).unparse(:required_fields => :tiny)
      else
        @version.convert(:standard).unparse(:required_fields => [:major, :minor, :tiny])
      end
    end
    
    def bundle
      case @config.version.format
      when :apple
        @version.unparse
      else
        @version.convert(:standard).tiny2
      end
    end
    
    def save
      if File.extname(@config.version.file) == '.yml'
        yaml = if File.exists?(@config.version.file)
          YAML.load_file(@config.version.file)
        else
          {}
        end
      
        yaml.merge!(@version.values_hash)
        
        File.open(@config.version.file, 'w') {|io| io.puts yaml.to_yaml }
      else
        File.open(@config.version.file, 'w') {|io| io.puts @version.unparse }
      end
    end
    
    # Accessors
    def build
      bump!(:build); self
    end
    
    def update
      bump!(:update); self
    end
    
    def patch
      bump!(:minor); self
    end
    
    def release(major = nil, version = nil)
      old_major   = @version.major
      old_version = @config.versions![old_major.to_s]
      
      bump!(:major)
      
      major   ||= @version.major
      version ||= Versionomy.parse(@config.versions![old_major.to_s] || "0.#{major}").bump(:minor).unparse
      
      if @config.versions![major] or @config.versions!.invert[version]
        raise "Version #{version} or major #{major} already exists"
      end
      
      @config.versions![major] = version; @config.save
      self
    end
    
    def bump(field)
      _tr = {
        :apple => {},
        :standard => {
          :update => :tiny, :build => :tiny2
        }
      }
      
      _field = _tr[@config.version.format][field] || field
      
      if @config.version.format == :apple and field == :update and @version.update.empty?
        @version.change(update: 'a')
      else
        @version.bump(field)
      end
    end
    
    def bump!(field)
      @version = bump(field); save; self
    end
    
    def to_s(format = @config.version.format)
      @version.convert(format).unparse
    end
    
    # Proxy
    def method_missing(m, *args, &blk)
      @version.send(m, *args, &blk)
    end
    
    def respond_to?(m)
      @version.respond_to?(m)
    end
    
  end
end
