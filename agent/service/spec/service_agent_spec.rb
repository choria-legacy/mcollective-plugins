#!/usr/bin/env rspec
require 'spec_helper'

describe "service agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/puppet-service.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("service", :agent_file => agent_file).plugin
    @agent.stubs(:require).with('puppet').returns(true)
  end

  describe "#meta" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#do_service_action" do
    before do
      logger = mock
      logger.stubs(:log)
      logger.stubs(:start)

      @plugin = mock
      @puppet_type = mock
      @puppet_service = mock
      @puppet_provider = mock

      MCollective::Log.configure(logger)
    end

    it "should succeed when action is not status and puppet version is not 0.24" do
      service = "service"
      action = "stop"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)

      @plugin.expects(:include?).with("service.hasrestart").returns(true)
      @plugin.expects(:[]).with("service.hasrestart").returns("1")
      @plugin.expects(:include?).with("service.hasstatus").returns(false)

      @puppet_service.expects(:provider).returns(@puppet_provider)

      Puppet.expects(:version).returns("0.xx")
      Puppet::Type.expects(:type).with(:service).returns(@puppet_type)

      @puppet_type.expects(:new).with(:name => service, :hasstatus => false, :hasrestart => true).returns(@puppet_service)

      @puppet_provider.expects(:send).with(action)
      @puppet_provider.expects(:status).returns(0)

      result = @agent.call("stop", :service => service)
      result.should be_successful
      result.should have_data_items({"status" => "0"})

    end

    it "should succeed when action is status and puppet version is not 0.24" do
      service = "service"
      action = "status"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)

      @plugin.expects(:include?).with("service.hasrestart").returns(true)
      @plugin.expects(:[]).with("service.hasrestart").returns("1")
      @plugin.expects(:include?).with("service.hasstatus").returns(false)

      @puppet_service.expects(:provider).returns(@puppet_provider)

      Puppet.expects(:version).returns("0.xx")
      Puppet::Type.expects(:type).with(:service).returns(@puppet_type)

      @puppet_type.expects(:new).with(:name => service, :hasstatus => false, :hasrestart => true).returns(@puppet_service)

      @puppet_provider.expects(:status).returns(0)

      result = @agent.call("status", :service => service)
      result.should be_successful
      result.should have_data_items({"status" => "0"})

    end

    it "should succeed when action is not status and puppet version is 0.24" do
      service = "service"
      action = "stop"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)

      @plugin.expects(:include?).with("service.hasrestart").returns(true)
      @plugin.expects(:[]).with("service.hasrestart").returns("1")
      @plugin.expects(:include?).with("service.hasstatus").returns(false)

      @puppet_service.expects(:provider).returns(@puppet_provider)

      Puppet.expects(:version).returns("0.24")

      Puppet::Type.expects(:type).with(:service).twice.returns(@puppet_type)

      @puppet_type.expects(:clear)
      @puppet_type.expects(:create).with(:name => service, :hasstatus => false, :hasrestart => true).returns(@puppet_service)

      @puppet_provider.expects(:send).with(action)
      @puppet_provider.expects(:status).returns(0)

      result = @agent.call("stop", :service => service)
      result.should be_successful
      result.should have_data_items({"status" => "0"})

    end

    it "should succeed when action is status and puppet version is 0.24" do
      service = "service"
      action = "status"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)

      @plugin.expects(:include?).with("service.hasrestart").returns(true)
      @plugin.expects(:[]).with("service.hasrestart").returns("1")
      @plugin.expects(:include?).with("service.hasstatus").returns(false)

      @puppet_service.expects(:provider).returns(@puppet_provider)

      Puppet.expects(:version).returns("0.24")

      Puppet::Type.expects(:type).with(:service).twice.returns(@puppet_type)

      @puppet_type.expects(:clear)
      @puppet_type.expects(:create).with(:name => service, :hasstatus => false, :hasrestart => true).returns(@puppet_service)

      @puppet_provider.expects(:status).returns(0)

      result = @agent.call("status", :service => service)
      result.should be_successful
      result.should have_data_items({"status" => "0"})

    end

    it "should fail on exception raised" do
      @agent.expects(:get_puppet).raises("Exception")
      result = @agent.call("status", :service =>"service")
      result.should be_aborted_error
    end

  end
end
