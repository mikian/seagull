require 'app_conf'

module Seagull
  class Configuration < AppConf
    def initialize(defaults = {})
      super()
      
      self.load('.seagull.yml') if File.exists?(".seagull.yml")
      self.from_hash(defaults)
    end
  end
end
