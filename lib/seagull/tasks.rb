require 'rake'
require 'rake/tasklib'
require 'vandamme'
require 'date'
require 'term/ansicolor'
require 'seagull/configuration'

module Seagull
  class Tasks < ::Rake::TaskLib
    def initialize(namespace = :seagull, &block)
      @configuration = Configuration.new
      @namespace     = namespace
      
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
          
          file @configuration.dsym_full_path(type) => @configuration.archive_full_path(type) do
            dsym_path = File.expand_path(Dir["#{@configuration.archive_full_path(type)}/dSYMS/*"].first)
            Dir.chdir dsym_path do
              sh("/usr/bin/zip --symlinks --verbose --recurse-paths '#{@configuration.dsym_full_path(type)}' .")
            end
          end
        end
        
        ['beta', 'release'].each do |type|
          namespace(type) do
            desc "Archive the #{type} version as an XCArchive file"
            task archive: [@configuration.archive_full_path(type)]
          
            desc "Package the #{type} version as an IPA file"
            task package: [@configuration.ipa_full_path(type), @configuration.dsym_full_path(type)]
            
            if @configuration.deployment_strategies
              desc "Prepare your app for deployment"
              task prepare: ['git:verify', :package] do
                @configuration.deployment_strategy(type).prepare
              end
          
              desc "Deploy the beta using your chosen deployment strategy"
              task deploy: [:prepare] do
                @configuration.deployment_strategy(type).deploy
              end
          
              desc "Deploy the last build"
              task redeploy: [:prepre, :deploy]
            end
            
          end
          
          desc "Build, package and deploy beta build"
          task type => ["#{type}:deploy"] do
          end
        end
        
        # Version control
        namespace(:version) do
          desc "Bumps build number"
          task bump: ['git:verify:dirty'] do
            sh("agvtool bump -all")
            @configuration.reload_version!
            
            # Edit changelog
            Rake::Task["#{@namespace}:changelog:edit"].invoke
            Rake::Task["#{@namespace}:version:commit"].invoke
            Rake::Task["#{@namespace}:version:tag"].invoke
          end
          
          task :tag do
            current_tag = %x{git describe --exact-match `git rev-parse HEAD` 2>/dev/null}.strip
            unless current_tag == @configuration.version_tag
              sh("git tag -m 'Released version #{@configuration.full_version}' -s '#{@configuration.version_tag}'")
            end
          end
          
          task :commit do
            ver_files = %x{git status --porcelain}.split("\n").collect{|a| Shellwords.escape(a.gsub(/[ AM\?]+ (.*)/, '\1'))}
            
            Dir.chdir(git_directory) do
              sh("git add #{ver_files.join(' ')}")
              sh("git commit -m 'Bumped version to #{@configuration.full_version}' #{ver_files.join(' ')}")
            end
          end
        end
        
        namespace(:changelog) do
          desc "Edit changelog for current version"
          task :edit do
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
          namespace(:verify) do
            # Verify GIT tag
            task :tag do
              current_tag = %x{git describe --exact-match `git rev-parse HEAD` 2>/dev/null}.strip
              unless current_tag == @configuration.version_tag
                puts ""
                puts Term::ANSIColor.red("!!! Current commit is not properly tagged in GIT. Please tag and release version.")
                puts ""

                fail unless ENV['IGNORE_GIT_TAG']
              end
            end
            
            # Verify dirty
            task :dirty do
              unless %x{git status -s --ignore-submodules=dirty 2> /dev/null}.empty?
                puts ""
                puts Term::ANSIColor.red("!!! Current GIT tree is dirty. Please commit changes before building release.")
                puts ""
                
                fail unless ENV['IGNORE_GIT_DIRTY']
              end
            end
          end
          
          task verify: ['verify:tag', 'verify:dirty']
        end
        
        def xctool(*args)
          sh("#{@configuration.xctool_path} #{args.join(" ")}")
        end

        def xcodebuild(*args)
          sh("#{@configuration.xcodebuild_path} #{args.join(" ")} | xcpretty -c; exit ${PIPESTATUS[0]}")
        end
      end
    end

    def git_directory
      original_cwd = Dir.pwd

      loop do
        if File.directory?('.git')
          git_dir = Dir.pwd
          Dir.chdir(original_cwd) and return git_dir
        end

        Dir.chdir(original_cwd) and return if Pathname.new(Dir.pwd).root?
        
        Dir.chdir('..')
      end
    end
  end
end