#!/usr/bin/env rspec
require 'spec_helper'

module Mcollective
  describe "puppetd application" do
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/puppetd.rb"])
      @util = MCollective::Test::ApplicationTest.new("puppetd", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description" do
        @app.should have_a_description
      end
    end

    describe "#post_option_parser" do
      it "should raise an exception if no command has been specified" do
        expect{
          @app.post_option_parser({})
        }.to raise_error("Please specify an action.")
      end

      it "should raise an exception if the given command doesn't match the list of puppetd commands" do
        ARGV << "invalid"
        expect{
          @app.post_option_parser(:command => "")
        }.to raise_error("Action must be enable, disable, runonce, runonce, runall, status, summary, or count")
      end

      it "should set command and concurrency" do
        ARGV << "enable"
        ARGV << "1"
        configuration = {:command => "", :concurrency => ""}
        @app.post_option_parser(configuration)
        configuration[:command].should == "enable"
        configuration[:concurrency].should == 1
      end
    end

    describe "#log" do
      it "should print a log statement with a time" do
        @app.expects(:puts)
        @app.log("foo")
      end
    end

    describe "#waitfor" do
      it "should return if concurrency is greater than the amount of puppet runs" do
        rpcclient_mock = mock

        rpcclient_mock.expects(:status).yields({:body => {:data => {:running => 0}}})
        @app.waitfor(1, rpcclient_mock)
      end

      it "should log a warning and continue of the rpcclient response is misformed" do
        rpcclient_mock = mock

        rpcclient_mock.expects(:status).yields(nil)
        @app.expects(:log).with("Failed to get node status for undefined method `[]' for nil:NilClass; continuing")
        @app.waitfor(1, rpcclient_mock)
      end

      it "should wait if the amount of puppet runs are greater than the concurrency" do
        rpcclient_mock = mock
        rpcclient_mock.expects(:status).yields({:body => {:data => {:running => 0}}})
        rpcclient_mock.expects(:status).yields({:body => {:data => {:running => 1}}})

        @app.expects(:log).with("Currently 1 nodes running; waiting")
        @app.expects(:sleep).with(2)

        @app.waitfor(1, rpcclient_mock)
      end
    end

    describe "#main" do
      it "should exit with message if command is runall and concurrency is 0" do
        @app.stubs(:configuration).returns({:command => "runall", :concurrency => 0})
        @app.expects(:puts).with("Concurrency is 0; not running any nodes")
        @app.expects(:rpcclient).with("puppetd", :options => nil)
        expect{
          @app.main
        }.to raise_error("exit")
      end

      it "should run puppet on all nodes if command is runall and concurrency is > 0" do
        rpcclient_mock = mock

        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        @app.stubs(:configuration).returns({:command => "runall", :concurrency => 1})
        @app.stubs(:log)
        rpcclient_mock.expects(:progress=).with(false)
        rpcclient_mock.expects(:discover).returns(["node1","node2"])
        @app.expects(:waitfor).with(1, rpcclient_mock).twice
        rpcclient_mock.expects(:custom_request).with("runonce", {:forcerun => true}, "node1", {"identity" => "node1"}).returns([:statusmsg => "success"])
        rpcclient_mock.expects(:custom_request).with("runonce", {:forcerun => true}, "node2", {"identity" => "node2"}).returns(false)
        @app.expects(:log).with("node1 schedule status: success")
        @app.expects(:log).with("node2 returned unknown output: false\n")
        @app.stubs(:sleep).with(1)
        rpcclient_mock.expects(:disconnect)

        @app.main
      end

      it "should do a single puppet run if command is runonce" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns({:command => "runonce", :force => true})
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        @app.expects(:printrpc)
        rpcclient_mock.expects(:runonce).with(:forcerun => true)
        rpcclient_mock.expects(:disconnect)

        @app.main
      end

      it "should display status if command is status" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns({:command => "status"})
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        rpcclient_mock.expects(:send).returns([
          {
            :sender     => "node1",
            :statuscode => 0,
            :data       => {:output => "Currently idling; success"}
          },
          {
            :sender     => "node2",
            :statuscode => 1,
            :statusmsg  => "failure"
          }
        ])
        @app.expects(:puts).with("node1                                    Currently idling; success")
        @app.expects(:puts).with("node2                                    failure")
        @util.config.stubs(:color)
        rpcclient_mock.expects(:disconnect)

        @app.main
      end

      it "should dislpay last run summary if command is summary" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns({:command => "summary"})
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        @app.expects(:printrpc)
        rpcclient_mock.expects(:last_run_summary)
        rpcclient_mock.expects(:disconnect)

        @app.main
      end

      it "should raise an exception and continue if node status cannot be retrieved and command is set to count" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns({:command => "count"})
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        rpcclient_mock.expects(:progress=).with(false)
        rpcclient_mock.expects(:status).yields(nil)
        rpcclient_mock.expects(:disconnect)
        @app.expects(:log).with("Failed to get node status for undefined method `[]' for nil:NilClass; continuing")

        @app.main
      end

      it "should display node counts if command is set to count" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns({:command => "count"})
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        rpcclient_mock.expects(:progress=).with(false)
        rpcclient_mock.expects(:status).yields(:body => {:data => {
          :running => "1",
          :enabled => "1",
          :stopped => "0",
          :idling  => "0"
        }})
        @app.expects(:puts).with("          Nodes currently enabled: 1")
        @app.expects(:puts).with("         Nodes currently disabled: 0")
        @app.expects(:puts).with("Nodes currently doing puppet runs: 1")
        @app.expects(:puts).with("          Nodes currently stopped: 0")
        @app.expects(:puts).with("           Nodes currently idling: 0")
        rpcclient_mock.expects(:disconnect)

        @app.main
      end

      it "should print the response from any other rpc's" do
        rpcclient_mock = mock

        @app.stubs(:configuration).returns(:command => "enable")
        @app.expects(:rpcclient).with("puppetd", :options => nil).returns(rpcclient_mock)
        rpcclient_mock.expects(:send).with("enable")
        @app.expects(:printrpc)
        rpcclient_mock.expects(:disconnect)

        @app.main
      end
    end
  end
end
