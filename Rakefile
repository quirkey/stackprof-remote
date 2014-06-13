# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "stackprof-remote"
  gem.homepage = "http://github.com/quirkey/stackprof-remote"
  gem.license = "MIT"
  gem.summary = %Q{A Middleware and CLI for fetching and interacting with StackProf dumps}
  gem.description = %Q{stackprof-remote consists of a middleware for easy creation and retreival of
                       stackprof sampling profiler dumps from a remote machine, and a wrapper around
                       pry (stackprof-cli) to create an interactive session for navigating stackprof
                       dumps.}
  gem.email = "aaron@quirkey.com"
  gem.authors = ["Aaron Quint"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['test'].execute
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "stackprof-remote #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
