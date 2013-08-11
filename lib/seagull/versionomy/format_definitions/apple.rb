require 'versionomy'

module Versionomy
  module Format
    def self.apple
      get('apple')
    end
    
    module Apple
      module ExtraMethods
        
      end
      
      def self.create
        schema_ = Schema.create do
          field(:major, :type => :integer, :default_value => 1) do
            field(:minor, :type => :string, :default_value => 'A') do
              field(:build, :type => :integer, :default_value => 1) do
                field(:update, :type => :string)
              end
            end
          end
          
          add_module(Format::Apple::ExtraMethods)
        end
        
        Format::Delimiter.new(schema_) do
          field(:major) do
            recognize_number(:delimiter_regexp => '', :default_delimiter => '')
          end
          
          field(:minor) do
            recognize_regexp('[A-Z]',:delimiter_regexp => '', :default_delimiter => '')
          end
          
          field(:build) do
            recognize_number(:delimiter_regexp => '', :default_delimiter => '')
          end
          
          field(:update) do
            recognize_regexp('[a-z]', :delimiter_regexp => '', :default_delimiter => '', :default_value_optional => true)
          end
        end
      end
    end
      
    register('apple', Format::Apple.create, true)
  end
  
  module Conversion
    module Apple
      def self.create_standard_to_apple
        Conversion::Parsing.new do
          to_modify_original_value do |original_, convert_params_|
            binding.pry
            apple_version = {
              major: original_.major,
              minor: ('A'..'Z').to_a[original_.minor],
              build: original_.tiny2,
              update: (original_.tiny > 0 ? ('a'..'z').to_a[original_.tiny - 1] : nil),
            }
            Versionomy.create(apple_version, :apple)
          end
        end
      end
      
      def self.create_apple_to_standard
        Conversion::Parsing.new do
          to_modify_original_value do |original_, convert_params_|
            if convert_params_[:versions]
              major, minor = convert_params_[:versions][original_.major].split(".").map(&:to_i)
              tiny         = ('A'..'Z').to_a.index(original_.minor)
              tiny2        = original_.build
              patchlevel   = !original_.update.empty? ? (('a'..'z').to_a.index(original_.update) + 1) : nil
            else
              major      = original_.major
              minor      = ('A'..'Z').to_a.index(original_.minor)
              tiny       = !original_.update.empty? ? (('a'..'z').to_a.index(original_.update) + 1) : nil
              tiny2      = original_.build
              patchlevel = nil
            end

            Versionomy.create({major: major, minor: minor, tiny: tiny, tiny2: tiny2, patchlevel: patchlevel})
          end
        end
      end
    end
    
    register(:standard, :apple, Conversion::Apple.create_standard_to_apple, true)
    register(:apple, :standard, Conversion::Apple.create_apple_to_standard, true)
  end
end
