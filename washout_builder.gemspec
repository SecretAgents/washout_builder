require File.expand_path("../lib/washout_builder/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "washout_builder"
  s.version     = WashoutBuilder.gem_version
  s.platform    = Gem::Platform::RUBY
  s.summary     = "WashOut Soap Service HTML-Documentation generator (extends WashOut https://github.com/inossidabile/wash_out/)"
  s.email       = "raoul_ice@yahoo.com"
  s.homepage    = "http://github.com/bogdanRada/washout_builder/"
  s.description = "WashOut Soap Service HTML-Documentation generator (extends WashOut https://github.com/inossidabile/wash_out/) "
  s.authors     = ["bogdanRada"]
  s.date =  Date.today

  s.licenses = ["MIT"]
  s.files = `git ls-files`.split("\n")
  s.test_files = s.files.grep(/^(spec)/)
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'wash_out', '~> 0.9.1', '>= 0.9.1'
  s.add_runtime_dependency 'activesupport', '~> 4.0', '>= 4.0'

  s.add_development_dependency 'wasabi', '~> 3.5', '>= 3.5'
  s.add_development_dependency 'savon', '~> 2.11', '>= 2.11'
  s.add_development_dependency 'httpi', '~> 2.4', '>= 2.4'
  s.add_development_dependency 'nokogiri', '~> 1.6', '>= 1.6'

  s.add_development_dependency 'rspec-rails', '~> 3.3', '>= 3.3'
  s.add_development_dependency 'guard', '~> 2.13', '>= 2.13'
  s.add_development_dependency 'guard-rspec', '~> 4.6', '>= 4.6'
  s.add_development_dependency 'appraisal', '~> 2.0', '>= 2.0'
  s.add_development_dependency 'simplecov', '~> 0.9', '>= 0.9'
  s.add_development_dependency 'simplecov-summary', '~> 0.0.4', '>= 0.0.4'
  s.add_development_dependency 'mocha','~> 1.1', '>= 1.1'
  s.add_development_dependency 'coveralls','~> 0.8', '>= 0.8'
  s.add_development_dependency 'test-unit','~> 3.1', '>= 3.1'
  #  s.add_development_dependency 'codeclimate-test-reporter','~> 0.3', '>= 0.3'
  #  s.add_development_dependency 'rubyntlm','~> 0.3.4', '>= 0.3'
  s.add_development_dependency 'rvm-tester','~> 1.1', '>= 1.1'
  s.add_development_dependency 'wwtd','~> 1.0', '>= 1.0'

  s.add_development_dependency 'capybara', '~> 2.5', '>= 2.5'
  s.add_development_dependency 'selenium-webdriver',  '~> 2.41', '>= 2.41.0'
  s.add_development_dependency 'headless','~> 2.2', '>= 2.2'

  s.add_development_dependency 'rubocop',  '~> 0.3', '>= 0.33'
  s.add_development_dependency 'phare', '~> 0.7', '>= 0.7'
  s.add_development_dependency 'yard', '~> 0.8.7', '>= 0.8.7'
  s.add_development_dependency 'yard-rspec', '~> 0.1', '>= 0.1'
  s.add_development_dependency 'redcarpet', '~> 3.3', '>= 3.3'
  s.add_development_dependency 'github-markup', '~> 1.4', '>= 1.4'
  s.add_development_dependency 'inch', '~> 0.6'
  s.add_development_dependency 'guard-inch', '~> 0.2.0'
end
