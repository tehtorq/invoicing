# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "invoicing/version"

Gem::Specification.new do |s|
  s.name        = "invoicing"
  s.version     = Invoicing::VERSION
  s.authors     = ["Douglas Anderson", "Jeffrey van Aswegen", ]
  s.email       = ["i.am.douglas.anderson@gmail.com", "jeffmess@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{ An invoicing gem. }
  s.description = %q{ Manage invoices. }

  s.rubyforge_project = "uomi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activesupport"
  s.add_dependency "activerecord", "~> 3.0"
  s.add_dependency "i18n"
  s.add_dependency "workflow", '= 0.8.7'
  
  s.add_development_dependency 'combustion', '~> 0.3.1'
end
