require 'bundler/setup'
require 'bundler/gem_tasks'
require 'appraisal'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'
Coveralls::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace '] if ENV['DEBUG']
end

# desc "Prepare dummy application"
# task :prepare do
#  ENV["RAILS_ENV"] ||= 'test'
#  require File.expand_path("./spec/dummy/config/environment", File.dirname(__FILE__))
#  Dummy::Application.load_tasks
#  Rake::Task["db:test:prepare"].invoke
# end

unless ENV['TRAVIS']
  require 'rvm-tester'
  RVM::Tester::TesterTask.new(:suite) do |t|
    t.rubies = %w(1.9.3 2.0.0 2.1.0) # which versions to test (required!)
    t.bundle_install = true # updates Gemfile.lock, default is true
    t.use_travis = true # looks for Rubies in .travis.yml (on by default)
    t.command = 'bundle exec rake' # runs plain "rake" by default
    t.env = { 'VERBOSE' => '1', 'RAILS_ENV' => 'test', 'RACK_ENV' => 'test' } # set any ENV vars
    t.num_workers = 5 # defaults to 3
    t.verbose = true # shows more output, off by default
  end
end

desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
  if ENV['TRAVIS']
    exec(' bundle exec appraisal install && bundle exec rake appraisal spec && bundle exec rake coveralls:push')
  else
    exec('  bundle exec appraisal install && bundle exec rake appraisal spec')
  end
end
