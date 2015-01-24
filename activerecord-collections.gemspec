$:.push File.expand_path("../lib", __FILE__)
require "active_record/collections/version"

Gem::Specification.new do |s|
  s.name        = "activerecord-collections"
  s.version     = ActiveRecord::Collections::VERSION
  s.summary     = "Create collections of records, represented by ActiveRecord::Relation query criteria."
  s.description = "Create collections of records, represented by ActiveRecord::Relation query criteria which can be serialized and passed around without executing queries or loading records."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/activerecord-collections"

  s.add_dependency "activerecord"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "factory_girl"
  s.add_development_dependency "faker"
end
