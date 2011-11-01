#!/usr/bin/env rspec
require 'spec_helper'

describe "nrpe agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/nrpe.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("nrpe", :agent_file => agent_file).plugin
  end

  describe "#metda" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#runcommand" do
    it "should reply with statusmessage 'OK' of exitcode is 0" do
      @agent.expects(:plugin_for_command).with("foo").returns:cmd => ("foo")
      @agent.expects(:run).with("foo", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :perfdata=>"")
      result[:statusmsg].should == "OK"
    end

    it "should reply with statusmessage 'WARNING' of exitcode is 1" do
      @agent.expects(:plugin_for_command).with("foo").returns:cmd => ("foo")
      @agent.expects(:run).with("foo", :stdout => :output, :chomp => true).returns(1)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>1, :perfdata=>"")
      result[:statusmsg].should == "WARNING"
    end

    it "should reply with statusmessage 'CRITICAL' of exitcode is 2" do
      @agent.expects(:plugin_for_command).with("foo").returns:cmd => ("foo")
      @agent.expects(:run).with("foo", :stdout => :output, :chomp => true).returns(2)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>2, :perfdata=>"")
      result[:statusmsg].should == "CRITICAL"
    end

    it "should reply with statusmessage UKNOWN if exitcode is something else" do
      @agent.expects(:plugin_for_command).with("foo").returns:cmd => ("foo")
      @agent.expects(:run).with("foo", :stdout => :output, :chomp => true)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:exitcode=>nil, :perfdata=>"")
      result[:statusmsg].should == "UNKNOWN"
    end

    it "should fail on an unknown command" do
      @agent.expects(:plugin_for_command).with("foo").returns(nil)
      result = @agent.call(:runcommand, :command => "foo")
      result.should be_aborted_error
      result.should have_data_items(:output => "No such command: foo", :exitcode => 3)
    end
  end

  describe "#plugin_for_command" do
    it "should return the command from nrpe.conf_dir if it is set" do
      @agent.config.stubs(:pluginconf).returns("nrpe.conf_dir" => "/foo", "nrpe.conf_file" => "bar.cfg")
      @agent.stubs(:request).returns(:command => "command")
      File.expects(:exist?).with("/foo/bar.cfg").returns(true)
      File.expects(:readlines).with("/foo/bar.cfg").returns(["command[command]=run"])
      @agent.expects(:run).with("run", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:runcommand, :command => "run")
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :perfdata=>"")
      result[:statusmsg].should == "OK"
    end

    it "should return the command from /etc/nagios/nrpe.d if nrpe.conf_dir is unset" do
      @agent.config.stubs(:pluginconf).returns("")
      @agent.stubs(:request).returns(:command => "command")
      File.expects(:exist?).with("/etc/nagios/nrpe.d/command.cfg").returns(true)
      File.expects(:readlines).with("/etc/nagios/nrpe.d/command.cfg").returns(["command[command]=run"])
      @agent.expects(:run).with("run", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:runcommand, :command => "run")
      result.should be_successful
      result.should have_data_items(:exitcode=>0, :perfdata=>"")
      result[:statusmsg].should == "OK"
    end

  end

end
