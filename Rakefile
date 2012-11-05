specdir = File.join([File.dirname(__FILE__), "spec"])

require "#{specdir}/spec_helper.rb"
require 'rake'
require 'rspec/core/rake_task'

desc "Run agent and application tests"
RSpec::Core::RakeTask.new(:test) do |t|
    t.pattern = ['agent/**/spec/*_spec.rb', 'simplerpc_authorization/**/spec/*_spec.rb']
    t.rspec_opts = File.read("#{specdir}/spec.opts").chomp
end

task :default => :test
