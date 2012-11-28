#!/usr/bin/env rspec
require 'spec_helper'

describe "puppetconf agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__),"../agent/puppetconf.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("puppetconf", :agent_file => agent_file).plugin
    #what are
    @agent.instance_variable_set("@lockfile","spec_test_lock_file")
    @agent.instance_variable_set("@pidfile","spec_test_pid_file")
  end
  
  describe "environment" do
    it "should change the environment entry in the puppet.conf" do
      @agent.instance_variable_set("@environment", "spec_test_environment")
      result = @agent.call(:environment,:newval => "master")
      #should we check that the actuall value in the ini
      result.should be_successfull
      result.should have_data_items(:output => "Succesfully changed environment")
    end
  end
  
  describe "server" do
    it "should change the server entry in the puppet.conf" do
      @agent.instance_variable_set("@server", "spec_test_server")
      result = @agent.call(:server,:newval => "master")
      #should we check that the actuall value in the ini
      result.should be_successfull
      result.should have_data_items(:output => "Succesfully changed server")
    end
  end
  
end
    
