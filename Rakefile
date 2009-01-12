require 'rubygems'
require 'rake/testtask'
require 'rake/clean'
Gem::manage_gems
require 'rake/gempackagetask'
require File.join(File.dirname(__FILE__), 'lib/smurftp/version')

task :default => [:package]

spec = Gem::Specification.new do |s|
  s.name = "smurftp"
  s.version = Smurftp::VERSION::STRING
  s.author = "Andrew Gruner"
  s.email = "andrew@divineflame.com"
  s.homepage = "http//github.com/divineflame/smurftp"
  s.summary = "Creates a que of recently modified files for uploading to a server"
  files = FileList["**/**/**"]
  files.exclude 'pkg'
  files.exclude 'contrib'
  s.files = files.to_a
  s.test_files =  Dir.glob("test/*_test.rb")
  s.add_dependency("haml", ">=2.0.0")
  s.add_dependency("mongrel")
  s.executables=['smurftp']
end

Rake::GemPackageTask.new(spec) do |pkg|
end

desc "Run all unit tests"
Rake::TestTask.new(:test) do |t|
  t.test_files = Dir.glob("test/*_test.rb")
  t.verbose = true
end
