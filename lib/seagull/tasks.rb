require 'rake'
require 'rake/tasklib'
require 'seagull/configuration'

module Seagull
  class Tasks < ::Rake::TaskLib
    def initialize(namespace = '', &block)
      @configuration = Configuration.new(
        :configuration   => 'AdHoc',
        :build_dir       => 'build',
        :auto_archive    => true,
        :archive_path    => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :xcodebuild_path => "xcodebuild",
        :xcpretty        => true,
        
        :hockeyapp       => {},
        :testflight      => {},
      )
      @namespace = namespace
      
      yield @configuration if block_given?
      define
    end
    
  private
    def define
      namespace(@namespace) do
        desc "Build the beta release of the app"
        task :build => :clean do
          
        end
      end
    end
  end
end