# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ext_sti/version"

Gem::Specification.new do |s|
  s.name        = "ext_sti"
  s.version     = ExtSTI::VERSION
  s.authors     = ["Alexey Shcherbakov"]
  s.email       = ["schalexey@gmail.com"]
  s.homepage    = "http://github.com/fuCtor/ext_sti"
  s.summary     = %q{Extend ActiveRecord::Base for implement STI through association}
  s.description = %q{Implement pattern when inheritance column TYPE is taken from association}

  s.rubyforge_project = "ext_sti"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = %w[lib]  
end
