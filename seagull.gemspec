# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "seagull"
  spec.version       = "0.0.1"
  spec.authors       = ["Mikko Kokkonen"]
  spec.email         = ["mikko@owlforestry.com"]
  spec.description   = %q{Seagull makes managing XCode projects easy as flying is for seagulls}
  spec.summary       = %q{Manage Xcode projects with total control}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rake",     "~> 10.1"
  spec.add_dependency "app_conf", "~> 0.4.2"
  spec.add_dependency "xcpretty", "~> 0.1.3"
  spec.add_dependency "unicode",  "~> 0.4.4"
  spec.add_dependency "nokogiri", "~> 1.6.1"
  spec.add_dependency "vandamme", "~> 0.0.7"
  spec.add_dependency "json",     "~> 1.8.1"

  spec.add_development_dependency "rake",    "~> 10.1"
  spec.add_development_dependency "bundler", "~> 1.3"
end
