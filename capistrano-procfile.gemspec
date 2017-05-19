# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "capistrano-procfile"
  gem.version       = "0.1.0"
  gem.authors       = ["Nicolas Brousse"]
  gem.email         = ["n.brousse@pantographe.studio"]
  gem.description   = %q{Procfile specific Capistrano tasks}
  gem.summary       = %q{Procfile specific Capistrano tasks}
  gem.homepage      = "https://github.com/pantographe/capistrano-procfile"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "capistrano", "~> 3.1"

  gem.add_development_dependency "danger"
end
