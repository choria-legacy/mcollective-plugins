#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

module Puppet
  class Type
  end
end

describe "packages agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/puppet-packages.rb"])
    libdir = File.join([File.dirname(__FILE__), "../agent/"])
    @agent = MCollective::Test::LocalAgentTest.new("packages", :agent_file => agent_file, :config => {:libdir => libdir}).plugin

    # @agent.stubs(:require).with('puppet').returns(true)
  end

  describe "#meta" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#do_packages_action" do
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

    it "should succeed when action is uptodate and packages list is empty" do
      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages = []

      result = @agent.call("uptodate", "packages" => packages)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => []})
    end

    it "should fail when action is uptodate and package has release, but not version" do
      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages = [{ "name" => "foo", "version" => nil, "release" => "23" }]

      result = @agent.call("uptodate", "packages" => packages)
      result[:statuscode].should == 5
    end

    it "should succeed when action is uptodate and package is already installed - bzip2" do
      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "bzip2", "version" => nil, "release" => nil }]
      packages_reply   = [{ "name" => "bzip2", "version" => "1.0.5", "release" => "7.el6_0", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is installed - testtool" do
      system "yum", "erase", "-y", "testtool"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "testtool", "version" => nil, "release" => nil }]
      packages_reply   = [{ "name" => "testtool", "version" => "1.3.0", "release" => "23.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is upgraded - test-ws-1.0 - r1111 -> r3333" do
      system "yum", "erase",   "-y", "test-ws-1.0"
      system "yum", "install", "-y", "test-ws-1.0-0.1.0SNAPSHOT-1111.el6"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "test-ws-1.0", "version" => nil, "release" => nil }]
      packages_reply   = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "3333.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is partial upgraded - test-ws-1.0 - r1111 -> r2222" do
      system "yum", "erase",   "-y", "test-ws-1.0"
      system "yum", "install", "-y", "test-ws-1.0-0.1.0SNAPSHOT-1111.el6"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "2222.el6" }]
      packages_reply   = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "2222.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is downgraded - test-ws-1.0 - r3333 -> r1111" do
      system "yum", "erase",   "-y", "test-ws-1.0"
      system "yum", "install", "-y", "test-ws-1.0-0.1.0SNAPSHOT-3333.el6"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "1111.el6" }]
      packages_reply   = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "1111.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is partially downgraded - test-ws-1.0 - r3333 -> r2222" do
      system "yum", "erase",   "-y", "test-ws-1.0"
      system "yum", "install", "-y", "test-ws-1.0-0.1.0SNAPSHOT-3333.el6"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "2222.el6" }]
      packages_reply   = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "2222.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should succeed when action is uptodate and a package is partially downgraded - test-ws-1.0 - r2222 -> r1111" do
      system "yum", "erase",   "-y", "test-ws-1.0"
      system "yum", "install", "-y", "test-ws-1.0-0.1.0SNAPSHOT-2222.el6"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "1111.el6" }]
      packages_reply   = [{ "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "1111.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end

    it "should report failures when action is uptodate and one package is not available" do
      system "yum", "erase",   "-y", "testtool"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "testtool",         "version" => nil, "release" => nil },
                          { "name" => "testdoesnotexist", "version" => nil, "release" => nil }]
      packages_reply   = [{ "name" => "testtool",         "version" => "1.3.0", "release" => "23.el6", "status" => 0, "tries" => 1 },
                          { "name" => "testdoesnotexist", "version" => nil,     "release" => nil,      "status" => 1, "tries" => 3 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 1, "packages" => packages_reply})
    end

    it "should report success when action is uptodate and one package is given with version" do
      system "yum", "erase",   "-y", "testtool"

      @agent.config.expects(:pluginconf).times(3).returns(@plugin)
      packages_request = [{ "name" => "testtool",    "version" => "1.3.0",         "release" => "23.el6" },
                          { "name" => "test-ws-1.0", "version" => nil,             "release" => nil }]
      packages_reply   = [{ "name" => "testtool",    "version" => "1.3.0",         "release" => "23.el6",   "status" => 0, "tries" => 1 },
                          { "name" => "test-ws-1.0", "version" => "0.1.0SNAPSHOT", "release" => "3333.el6", "status" => 0, "tries" => 1 }]

      result = @agent.call("uptodate", "packages" => packages_request)
      result.should be_successful
      result.should have_data_items({"status" => 0, "packages" => packages_reply})
    end
  end
end
