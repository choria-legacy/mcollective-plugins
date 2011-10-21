$: << File.join([File.dirname(__FILE__), "lib"])

require 'rubygems'
require 'rspec'
require 'mcollective'
require 'mcollective/test'
require 'rspec/mocks'
require 'mocha'
require 'tempfile'

RSpec.configure do |config|
  config.mock_with :mocha
  config.include(MCollective::Test::Matchers)

  config.before :each do
    MCollective::PluginManager.clear
  end
end
