#!/usr/bin/env rspec
require 'spec_helper'

module MCollective
  describe "package application" do
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/package.rb"])
      @util = MCollective::Test::ApplicationTest.new("package", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description set" do
        @app.should have_a_description
      end
    end

    describe "#post_option_parser" do
      it "should raise an exception if package and actions are not specified" do
        @app.expects(:puts).with("Please specify an action and a package.")

        expect{
          @app.post_option_parser({})
        }.to raise_error("exit")
      end

      it "should raise an exception if action isn't install, update, uninstall, purge or status" do
        ARGV << "action"
        ARGV << "package"

        @app.expects(:puts).with("Action must be install, update, uninstall, purge, or status.")

        expect{
          @app.post_option_parser({})
        }.to raise_error("exit")
      end

      it "should set action and package" do
        ARGV << "install"
        ARGV << "package"

        configuration = {:action => "", :package => ""}
        @app.post_option_parser(configuration)

        configuration[:action].should == "install"
        configuration[:package].should == "package"
      end
    end

    describe "#validate_configuration" do
      it "should exit if filter is empty and user input is not 'y'" do
        @app.expects(:options).returns({:filter => nil})
        @app.stubs(:print)
        MCollective::Util.expects(:empty_filter?).returns(true)
        STDOUT.expects(:flush)
        STDIN.expects(:gets).returns("n")

        expect{
          @app.validate_configuration({})
        }.to raise_error("exit")
      end

      it "should return if filter is empty and user input is 'y'" do
        @app.expects(:options).returns({:filter => nil})
        @app.stubs(:print)
        MCollective::Util.expects(:empty_filter?).returns(true)
        STDOUT.expects(:flush)
        STDIN.expects(:gets).returns("y")

        @app.validate_configuration({})
      end

      it "should return if filter is not empty" do
        @app.expects(:options).returns({:filter => nil})
        MCollective::Util.expects(:empty_filter?).returns(false)

        @app.validate_configuration({})
      end
    end

    describe "#summarize" do
      it "should print package statistics" do
        stats = {:discovered => 1, :responses => 1, :blocktime => 100}
        versions = {"1.1" => 1}
        @app.stubs(:print)
        @app.expects(:puts).with("           Nodes: 1 / 1")
        @app.expects(:puts).with("1 * 1.1")
        @app.expects(:printf).with("    Elapsed Time: %.2f s\n\n", 100)
        @app.summarize(stats, versions)
      end
    end

    describe "#main" do
      before do
        @rpcclient_mock = mock
      end

      it "should print error when response statuscode is not 0" do
        @app.stubs(:configuration).returns({:action => "install", :package => "package"})
        @app.expects(:rpcclient).with("package", :options => nil).returns(@rpcclient_mock)
        @rpcclient_mock.expects(:send).with("install", :package => "package").returns([{:data => {:properties => ""}, :statuscode => 1, :sender => "node1", :statusmsg => "failure"}])
        @rpcclient_mock.expects(:stats)
        @app.expects(:summarize)
        @app.expects(:printf).with("%-40s error = %s\n", "node1", "failure")

        @app.main
      end

      it "should set version and release if statuscode is 0 and the response includes a version number" do
        @app.stubs(:configuration).returns({:action => "install", :package => "package"})
        @app.expects(:rpcclient).with("package", :options => nil).returns(@rpcclient_mock)
        @rpcclient_mock.expects(:send).with("install", :package => "package").returns([{:data => {:properties => {:version => "1", :release => "2", :name => "package"}}, :statuscode => 0, :sender => "node1", :statusmsg => "failure"}])
        @app.expects(:printf).with("%-40s version = %s-%s\n", "node1", "package", "1-2")
        @rpcclient_mock.expects(:stats)
        @app.expects(:summarize)

        @app.main
      end

      it "should set ensure status as version if version is not defined" do
        @app.stubs(:configuration).returns({:action => "install", :package => "package"})
        @app.expects(:rpcclient).with("package", :options => nil).returns(@rpcclient_mock)
        @rpcclient_mock.expects(:send).with("install", :package => "package").returns([{:data => {:properties => {:ensure => "latest"}}, :statuscode => 0, :sender => "node1", :statusmsg => "failure"}])
        @app.expects(:printf).with("%-40s version = %s\n", "node1", "latest")
        @rpcclient_mock.expects(:stats)
        @app.expects(:summarize)

        @app.main
      end
    end
  end
end
