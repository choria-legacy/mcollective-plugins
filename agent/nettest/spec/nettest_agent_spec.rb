#!/usr/bin/env rspec
require 'spec_helper'

describe "nettest agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/nettest.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("nettest", :agent_file => agent_file).plugin
    @agent.instance_variable_set("@lockfile", "spec_test_lock_file")
    @agent.instance_variable_set("@pidfile",  "spec_test_pid_file")
  end

  describe "#meta" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#ping" do
    it "should fail for non string fqdns" do
      result = @agent.call(:ping, :fqdn => nil)
      result.should be_invalid_data_error

      result = @agent.call(:ping)
      result.should be_missing_data_error
    end

    it "should set correct rtt if it can ping the host" do
      icmp = mock
      icmp.expects("ping?").returns(true)
      icmp.expects(:duration).returns(0.001)

      Net::Ping::ICMP.expects(:new).with("rspec").returns(icmp)

      result = @agent.call(:ping, :fqdn => "rspec")
      result.should be_successful
      result.should have_data_items(:rtt => "1.0")
    end

    it "should return failure when it cannot ping" do
      icmp = mock
      icmp.expects("ping?").returns(false)

      Net::Ping::ICMP.expects(:new).with("rspec").returns(icmp)

      result = @agent.call(:ping, :fqdn => "rspec")
      result.should be_successful
      result.should have_data_items(:rtt => "Host did not respond")
    end
  end

  describe "#connect" do
    it "should fail for invalid fqdn and port" do
      @agent.call(:connect).should be_missing_data_error
      @agent.call(:connect, :fqdn => "rspec").should be_missing_data_error
      @agent.call(:connect, :port => "rspec").should be_missing_data_error
    end

    it "should handle timeout errors on connection" do
      TCPSocket.expects(:new).raises(Timeout::Error)
      result = @agent.call(:connect, :fqdn => "rspec", :port => "80")
      result.should be_successful
      result.should have_data_items(:connect => "Connection timeout")
    end

    it "should report connection refused errors" do
      TCPSocket.expects(:new).raises(Errno::ECONNREFUSED)
      result = @agent.call(:connect, :fqdn => "rspec", :port => "80")
      result.should be_successful
      result.should have_data_items(:connect => "Connection Refused")
    end

    it "should report connected status correctly" do
      socket = mock
      socket.expects(:close)

      TCPSocket.expects(:new).with("rspec", 80).returns(socket)
      result = @agent.call(:connect, :fqdn => "rspec", :port => "80")
      result.should be_successful
      result.should have_data_items(:connect => "Connected")
    end
  end
end
