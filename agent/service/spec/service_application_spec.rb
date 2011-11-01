#!/usr/bin/env rspec
require 'spec_helper'

module MCollective
  describe "service application" do
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/service.rb"])
      @util = MCollective::Test::ApplicationTest.new("service", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description set" do
        @app.should have_a_description
      end
    end

    describe "#print_statistics" do
      it "should not print statistics if status_counter is 0" do
        @app.stubs(:print)
        @app.expects(:print).with("No responses received")
        @app.print_statistics({:responses => 1, :noresponsefrom => []}, {})
      end

      it "should print statistics if status_counter is > 0" do
        @app.stubs(:print)
        @app.expects(:print).with("started=1 ")
        @app.expects(:print).with("stopped=0 ")
        @app.expects(:print).with("errors=0 ")
        @app.print_statistics({:responses => 1, :noresponsefrom => []}, {"running" => 1, "stopped" => 0, "error" => 0})

      end
    end

    describe "#post_option_parser" do
      it "should raise an exception if service name and action are not specified" do
        expect{
          @app.post_option_parser({})
        }.to raise_error("Please specify service name and action")
      end

      it "should raise and exception if action name isn't stop, start, restart or status" do
        ARGV << "service"
        ARGV << "action"
        expect{
          @app.post_option_parser({})
        }.to raise_error("Action can only be start, stop, restart or status")
      end

      it "should set service and action" do
        ARGV << "service"
        ARGV << "start"

        configuration = {:service => "", :action => ""}
        @app.post_option_parser(configuration)
        configuration[:service].should == "service"
        configuration[:action].should == "start"
      end
    end

    describe "#validate_configuration" do
      it "should exit if filter is empty and user response is not y or yes" do
        MCollective::Util.expects(:empty_filter?).returns(true)
        @app.expects(:options).returns(:filter => nil)
        @app.stubs(:print)
        STDOUT.expects(:flush)
        STDIN.expects(:gets).returns("n")
        @app.expects(:exit!)

        @app.validate_configuration({})
      end

      it "should return if filter is empty and user response is y or yes" do
        MCollective::Util.expects(:empty_filter?).returns(true)
        @app.expects(:options).returns(:filter => nil)
        @app.stubs(:print)
        STDOUT.expects(:flush)
        STDIN.expects(:gets).returns("y")

        @app.validate_configuration({})
      end

      it "should return if filter is not empty" do
        MCollective::Util.expects(:empty_filter?).returns(false)
        @app.expects(:options).returns(:filter => nil)
        @app.validate_configuration({})
      end
    end

    describe "#main" do
      before do
        @rpcclient_mock = mock
      end

      it "should run a service command and list sender and status if verbose is false" do
        @app.stubs(:configuration).returns({:action => "start", :service => "service"})
        @app.expects(:rpcclient).with("service", :options => nil).returns(@rpcclient_mock)
        @rpcclient_mock.expects(:send).with("start", :service => "service").returns([{:sender => "node1", :data => {"status" => "running"}, :statuscode => 0, :statusmsg => "success"}])
        @rpcclient_mock.expects(:progress).returns(true)
        @rpcclient_mock.expects(:verbose).returns(false)
        @rpcclient_mock.expects(:disconnect)
        @rpcclient_mock.expects(:stats)
        @app.expects(:print_statistics)

        @app.main
      end

      it "should run a service command and display verbosely if verbose is true" do
        @app.stubs(:configuration).returns({:action => "start", :service => "service"})
        @app.expects(:rpcclient).with("service", :options => nil).returns(@rpcclient_mock)
        @rpcclient_mock.expects(:send).with("start", :service => "service").returns([{:sender => "node1", :data => {"status" => "running"}, :statuscode => 0, :statusmsg => "success"}])
        @rpcclient_mock.expects(:progress).returns(true)
        @rpcclient_mock.expects(:verbose).returns(true)
        @rpcclient_mock.expects(:disconnect)
        @rpcclient_mock.expects(:stats)
        @app.expects(:print_statistics)

        @app.main
      end

    end
  end
end
