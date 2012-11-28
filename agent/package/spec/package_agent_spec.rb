#!/usr/bin/env rspec
require 'spec_helper'

describe "package agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/package.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("package", :agent_file => agent_file).plugin
  end
  after :all do
    MCollective::PluginManager.clear
  end

  describe "#yum_clean" do
    it "should fail if /usr/bin/yum doesn't exist" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      result = @agent.call(:yum_clean)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find yum at /usr/bin/yum"
    end

    it "should succeed if run method returns 0" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should fail if the run method doesn't return 0" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(1)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
      result = @agent.call(:yum_clean)
      result.should be_aborted_error
      result.should have_data_items(:exitcode => 1)
    end

    it "should default to 'all' mode" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({})
      @agent.expects(:run).with("/usr/bin/yum clean all", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should support a configured mode" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "headers"})
      @agent.expects(:run).with("/usr/bin/yum clean headers", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:yum_clean)
      result.should be_successful
      result.should have_data_items(:exitcode => 0)
    end

    it "should support configured modes" do
      ["all", "headers", "packages", "metadata", "dbcache", "plugins", "expire-cache"].each do |mode|
        File.expects(:exist?).with("/usr/bin/yum").returns(true)
        @agent.config.expects(:pluginconf).returns({"package.yum_clean_mode" => "all"})
        @agent.expects(:run).with("/usr/bin/yum clean #{mode}", :stdout => :output, :chomp => true).returns(0)

        result = @agent.call(:yum_clean, :mode => mode)
        result.should be_successful
        result.should have_data_items(:exitcode => 0)
      end
    end
  end

  describe "#apt_update" do
    it "should fail if /usr/bin/apt-get doesn't exist" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:apt_update)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find apt-get at /usr/bin/apt-get"
    end

    it "should succeed if the agent responds to 'run' and the run method returns 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(0)
      result = @agent.call(:apt_update)
      result.should have_data_items(:exitcode => 0)
      result.should be_successful
    end

    it "should fail if the agent responds to 'run' and the run method doesn't return 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get update", :stdout => :output, :chomp => true).returns(1)
      result = @agent.call(:apt_update)
      result.should have_data_items(:exitcode => 1)
      result.should be_aborted_error
    end
  end

  describe "#checkupdates" do
    it "should fail if neither /usr/bin/yum or /usr/bin/apt-get are present" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find a compatible package system to check updates for"
    end

    it "should call yum_checkupdates if /usr/bin/yum exists" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:yum_checkupdates_action).returns(true)
      result = @agent.call(:checkupdates)
      result.should be_true
      result.should have_data_items(:package_manager=>"yum")
    end

    it "should call apt_checkupdates if /usr/bin/apt-get exists" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:apt_checkupdates_action).returns(true)
      result = @agent.call(:checkupdates)
      result.should have_data_items(:package_manager=>"apt")
      result.should be_true
    end
  end

  describe "#yum_checkupdates" do
    it "should fail if /usr/bin/yum does not exist" do
      File.expects(:exist?).with("/usr/bin/yum").returns(false)
      result = @agent.call(:yum_checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find yum at /usr/bin/yum"
    end

    it "should succeed if it responds to run and there are packages to update" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.expects(:do_yum_outdated_packages)
      result = @agent.call(:yum_checkupdates)
      result.should be_successful
      result.should have_data_items(:outdated_packages=>nil, :exitcode=>100)
    end
  end

  describe "#apt_checkupdates" do
    it "should fail if /usr/bin/apy-get does not exist" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(false)
      result = @agent.call(:apt_checkupdates)
      result.should be_aborted_error
      result[:statusmsg].should == "Cannot find apt at /usr/bin/apt-get"
    end

    it "should succeed if it responds to run and returns exit code of 0" do
      @agent.stubs("reply").returns({:output => "Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []", :exitcode => 0})

      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(0)

      result = @agent.call(:apt_checkupdates)
      result.should be_successful

    end

    it "should fail if it responds to 'run' but returns an error code that is not 0" do
      File.expects(:exist?).with("/usr/bin/apt-get").returns(true)
      @agent.expects(:run).with("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true).returns(1)
      result = @agent.call(:apt_checkupdates)
      result.should be_aborted_error
      result.should have_data_items(:outdated_packages=>[], :exitcode=>1)
    end
  end

  describe "#do_pkg_action" do
    before(:each) do
      @puppet_type = mock
      @puppet_type.stubs(:clear)
      @puppet_package = mock
    end

    describe "#install" do
      it "should install if the package is absent" do
        [:absent, :purged].each do |status|
          Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

          @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
          @puppet_package.expects(:provider).returns(@puppet_package)
          @puppet_package.expects(:install).returns(0)
          @puppet_package.expects(:properties).twice.returns({:ensure => status})
          @puppet_package.expects(:flush)

          result = @agent.call(:install, :package => "package")
          result.should be_successful
          result.should have_data_items(:ensure => status.to_s, :output => 0)
        end
      end

      it "should not install if the package is present" do
        Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

        @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
        @puppet_package.expects(:provider).returns(@puppet_package)
        @puppet_package.expects(:properties).twice.returns({:ensure => "123"})
        @puppet_package.expects(:flush)

        result = @agent.call(:install, :package => "package")
        result.should be_successful
        result.should have_data_items(:ensure => "123", :output => "")
      end
    end

    describe "#update" do
      it "should update unless the package is absent" do
        Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

        @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
        @puppet_package.expects(:provider).returns(@puppet_package)
        @puppet_package.expects(:update).returns(0)
        @puppet_package.expects(:properties).twice.returns({:ensure => :not_absent})
        @puppet_package.expects(:flush)

        result = @agent.call(:update, :package => "package")
        result.should be_successful
        result.should have_data_items(:ensure => "not_absent", :output => 0)
      end

      it "should not update if the package is not installed" do
        [:absent, :purged].each do |status|
          Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

          @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
          @puppet_package.expects(:provider).returns(@puppet_package)
          @puppet_package.expects(:properties).twice.returns({:ensure => status})
          @puppet_package.expects(:flush)

          result = @agent.call(:update, :package => "package")
          result.should be_successful
          result.should have_data_items(:ensure => status.to_s, :output => "")
        end
      end
    end

    describe "#uninstall" do
      it "should uninstall if the package is present" do
        Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

        @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
        @puppet_package.expects(:provider).returns(@puppet_package)
        @puppet_package.expects(:uninstall).returns(0)
        @puppet_package.expects(:properties).twice.returns({:ensure => :not_absent})
        @puppet_package.expects(:flush)

        result = @agent.call(:uninstall, :package => "package")
        result.should be_successful
        result.should have_data_items(:ensure => "not_absent", :output=>0)
      end

      it "should not uninstall if the package is absent" do
        [:absent, :purged].each do |status|
          Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

          @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
          @puppet_package.expects(:provider).returns(@puppet_package)
          @puppet_package.expects(:properties).twice.returns({:ensure => status})
          @puppet_package.expects(:flush)

          result = @agent.call(:uninstall, :package => "package")
          result.should be_successful
          result.should have_data_items(:ensure => status.to_s, :output => "")
        end
      end
    end

    describe "#status" do
      it "should return the status of the package" do
        Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

        @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
        @puppet_package.expects(:provider).returns(@puppet_package)
        @puppet_package.expects(:flush)
        @puppet_package.expects(:properties).returns({:status => "rspec"})

        result = @agent.call(:status, :package => "package")
        result.should be_successful
        result.should have_data_items(:status => "rspec", :output=>"")
      end
    end
    describe "#purge" do
      it "should run purge on the package object" do
        Puppet::Type.stubs(:type).with(:package).returns(@puppet_type)

        @puppet_type.expects(:new).with(:name => "package").returns(@puppet_package)
        @puppet_package.expects(:provider).returns(@puppet_package)
        @puppet_package.expects(:flush)
        @puppet_package.expects(:purge).returns("Purged")
        @puppet_package.expects(:properties)

        result = @agent.call(:purge, :package => "package")
        result.should be_successful
        result.should have_data_items(:output=>"Purged")
      end
    end
    describe "#Exceptions" do
      it "should fail if exception is raised" do
        Puppet::Type.stubs(:type).raises("Exception")
        result = @agent.call(:install, :package => "package")
        result.should be_aborted_error
        result[:statusmsg].should == "Exception"
      end
    end
  end
  describe "#do_yum_outdated_packages" do
    it "should not do anything with obsoleted packages" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.stubs(:reply).returns(:output => "Obsoleting")

      result = @agent.call(:yum_checkupdates)
      result.should be_successful
    end

    it "should return packages which need to be updated" do
      File.expects(:exist?).with("/usr/bin/yum").returns(true)
      @agent.expects(:run).with("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true).returns(100)
      @agent.stubs(:reply).returns(:output => "Package version repo", :outdated_packages => "foo")

      result = @agent.call(:yum_checkupdates)
      result.should be_successful
    end
  end
end
