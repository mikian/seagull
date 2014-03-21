require 'rake'
require 'rake/tasklib'
require 'vandamme'
require 'date'
require 'seagull/configuration'

module Seagull
  class Tasks < ::Rake::TaskLib
    def initialize(namespace = :seagull, &block)
      @configuration = Configuration.new(
        :configuration   => {:debug => 'Debug', :beta => 'AdHoc', :release => 'Release'},
        :build_dir       => 'build',
        :auto_archive    => true,
        :changelog_file  => File.expand_path('CHANGELOG.md'),
        :archive_path    => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :ipa_path        => File.expand_path("~/Library/Developer/Xcode/Archives"),
        :xctool_path     => "xctool",
        :xcodebuild_path => "xcodebuild",
        :workspace_path  => nil,
        :scheme          => nil,
        :app_name        => nil,
        :arch            => nil,
        :skip_clean      => false,
        :verbose         => false,
        :dry_run         => false,
        :xcpretty        => true,
        
        :deploy          => {},
      )
      @namespace = namespace
      
      yield @configuration if block_given?
      
      # Check we can find our xctool
      unless File.executable?(%x{which #{@configuration.xctool_path}}.strip)
        raise "xctool is required. Please install using Homebrew: brew install xctool."
      end

      unless File.executable?(%x{which #{@configuration.xcodebuild_path}}.strip)
        raise "xcodebuild is required. Please install XCode."
      end
      
      define
    end
    
  private
    def define
      # Detect some defaults
      namespace(@namespace) do
        task :clean do
          unless @configuration.skip_clean
            xctool @configuration.build_arguments, "clean"
          end
        end

        desc "Build and run tests"
        task test: [] do
          xctool @configuration.build_arguments(configuration: @configuration.configuration.debug, arch: 'i386', sdk: 'iphonesimulator'), "clean", "test", "-freshInstall", "-freshSimulator"
        end
        
        # File dependencies
        @configuration.configuration.to_hash.each do |type, conf|
          file @configuration.archive_full_path(type) do
            xctool @configuration.build_arguments(configuration: conf), "archive", "-archivePath", Shellwords.escape(@configuration.archive_full_path(type))
          end
        
          file @configuration.ipa_full_path(type) => @configuration.archive_full_path(type) do
            xcodebuild "-exportArchive", "-exportFormat", "ipa", "-archivePath", Shellwords.escape(@configuration.archive_full_path(type)), "-exportPath", Shellwords.escape(@configuration.ipa_full_path(type))
          end

        end
        
        ['beta', 'release'].each do |type|
          namespace(type) do
            desc "Archive the #{type} version as an XCArchive file"
            task archive: [@configuration.archive_full_path(type)]
          
            desc "Package the #{type} version as an IPA file"
            task package: [@configuration.ipa_full_path(type)]
          end
          
          desc "Build, package and deploy beta build"
          task type => ["#{type}:archive"] do
          end
        end
        
        # Version control
        namespace(:version) do
          desc "Bumps build number"
          task :bump do
            sh("agvtool bump -all")
            @configuration.reload_version!
          end
          
          desc "Edit changelog for current version"
          task :changelog do
            changelog = if File.exists?(@configuration.changelog_file)
              File.read(@configuration.changelog_file)
            else
              ""
            end

            tag      = %x{git describe --exact-match `git rev-parse HEAD` 2>/dev/null}.strip
            tag_date = Date.parse(%x{git log -1 --format=%ai #{tag}})
            
            # Parse current changelog
            parser = Vandamme::Parser.new(changelog: changelog, version_header_exp: '^\*\*?([\w\d\.-]+\.[\w\d\.-]+[a-zA-Z0-9])( \/ (\d{4}-\d{2}-\d{2}|\w+))?\*\*\n?[=-]*', format: 'markdown')
            changes = parser.parse
            
            # Write entry to changelog
            File.open('CHANGELOG.md', 'w') do |io|
              unless @configuration.full_version
                io.puts "**#{@configuration.full_version} / #{tag_date.strftime('%Y-%m-%d')}**"
                io.puts ""
                %w{FIXED SECURITY FEATURE ENHANCEMENT PERFORMANCE}.each do |kw|
                  io.puts " * **#{kw}** Describe changes here or remove if not required"
                end
                io.puts ""
              end
              io.puts changelog
            end
            sh("#{ENV['EDITOR']} CHANGELOG.md")
          end
        end
        
        namespace(:git) do
          task :verify do
            current_tag = %x{git describe --exact-match `git rev-parse HEAD` 2>/dev/null}.strip
            unless current_tag == @configuration.version_tag
              raise "Current commit is not properly tagged in GIT. Please tag and release version."
            end
          end
          
          task :tag do
            sh("git tag -m 'Released version #{@configuration.full_version}' -s '#{@configuration.version_tag}'")
          end
          
          task "commit:version" do
            ver_files = %W{
              #{APPNAME}.xcodeproj/project.pbxproj
              #{APPDIR}/#{APPNAME}-Info.plist
              CHANGELOG.md
            }.join(' ')
          
            system "git add #{ver_files}"
            system "git commit -m 'Bumped version to #{version}' #{ver_files}"
            system "git tag -m 'Released version #{version}' -s 'v#{version}'"
            system "git push --tags"
          end
        end
        
        def xctool(*args)
          sh("#{@configuration.xctool_path} #{args.join(" ")}")
        end

        def xcodebuild(*args)
          sh("#{@configuration.xcodebuild_path} #{args.join(" ")} | xcpretty -c; exit ${PIPESTATUS[0]}")
        end
      end
    end
  end
end