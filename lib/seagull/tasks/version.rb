require 'seagull/version'

module Seagull
  module Tasks
    class Version < Thor
      VERSION = Seagull::Version.instance
      CONFIG  = Seagull::Config.instance
      
      desc "print", "Prints current version (#{VERSION.to_s})"
      def print
        say_status "current", "Version %s (%s)" % [VERSION.marketing, VERSION.bundle], :blue
      end
      
      desc "list", "List all versions and majors"
      def list
        if CONFIG.version.format != :apple
          say_status "UNKNOWN", "Used version format not using version <-> major coding"
          exit
        end
        
        if !CONFIG.versions?
          say_status "UNKNOWN", "Versions and majors have not been defined"
          exit
        end
        
        table = [['Version', 'Major Version']]
        table += CONFIG.versions.collect{|k,v| ["%6s.%-3s" % v.split('.'), k.to_i]}.sort

        print_table table
      end
      
      desc "bumplist", "List all possible bump versions"
      def bumplist
        peeks    = [:release, :patch, :update, :build]
        versions = [['Type', 'Version']]
        versions += peeks.collect{|t| [t.to_s, VERSION.peek(t)]}
        
        print_table versions
      end
      
      desc "release [MAJOR] [VERSION]", "Releases new version (#{VERSION.peek(:release)})"
      def release(major = nil, version = nil)
        VERSION.release(major, version)
        
        say_status "RELEASE", "Version #{VERSION.to_s} has been released", :green
      rescue => e
        say_status "FAILED", e.message, :red
      end
      
      desc "patch", "Release new patch version (#{VERSION.peek(:patch)})"
      def patch
        VERSION.patch
        say_status "PATCH", "Version increased #{VERSION.to_s}"
      end
      
      desc "update", "Release new update (#{VERSION.peek(:update)})"
      def update
        VERSION.update
        say_status "update", "Version update to #{VERSION.to_s}"
      end
      
      desc "build [BUILDNUMBER]", "Increases build number (#{VERSION.peek(:build)}), optionally set to given number"
      def build(buildnumber = nil)
        if buildnumber
          VERSION.set(build: buildnumber)
        else
          VERSION.build
        end
        say_status "version", "Increased build number to #{VERSION.to_s}"
      end
    end
  end
end