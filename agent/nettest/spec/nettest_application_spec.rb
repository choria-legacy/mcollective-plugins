#!/usr/bin/env rspec
require 'spec_helper'

module Mcollective
  describe "nettest application" do
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/nettest.rb"])
      @util = MCollective::Test::ApplicationTest.new("nettest", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description" do
        @app.should have_a_description
      end
    end

    describe "#post_option_parser" do
      it "should raise an exception for no arguments" do
        expect {
          @app.post_option_parser({})
        }.to raise_error("Please specify an action and optional arguments")
      end

      it "should raise an exception for unknown actions" do
        ARGV << "action"
        ARGV << "rspec"

        expect {
          @app.post_option_parser({})
        }.to raise_error("Action can only to be ping or connect")
      end

      it "should set fqdn and port correctly in the configuration" do
        ARGV << "ping"
        ARGV << "rspec"

        configuration = {}
        @app.post_option_parser(configuration)

        configuration.should == {:action=>"ping", :arguments=>{:fqdn=>"rspec"}}

        ARGV << "connect"
        ARGV << "rspec"
        ARGV << "80"

        configuration = {}
        @app.post_option_parser(configuration)

        configuration.should == {:action=>"connect", :arguments=>{:port=>"80", :fqdn=>"rspec"}}
      end
    end

    describe "#validate_configuration" do
      it "should check if no filter is supplied and ask confirmation expecting y or yes" do
        MCollective::Util.expects("empty_filter?").returns(true).twice

        @app.expects(:print).with("Do you really want to perform network tests unfiltered? (y/n): ").twice
        @app.expects(:options).returns({}).twice
        STDIN.expects(:gets).returns("y")
        @app.expects("exit!").never
        @app.validate_configuration({})

        STDIN.expects(:gets).returns("yes")
        @app.validate_configuration({})
      end

      it "should exit unless y or yes is supplied" do
        MCollective::Util.expects("empty_filter?").returns(true)

        @app.expects(:print).with("Do you really want to perform network tests unfiltered? (y/n): ")
        @app.expects(:options).returns({})

        @app.expects("exit!")
        STDIN.expects(:gets).returns("n")
        @app.validate_configuration({})
      end
    end

    describe "#process_connect_result" do
      it "should correctly handle connected results" do
        @app.expects(:puts).with(regexp_matches(/rspec.+status=connected/))
        @app.process_connect_result("connected", {:sender => "rspec", :statusmsg => "OK"}, (stats = {}), false)
        stats.should == {:connect => [1, 0, 0]}
      end

      it "should correctly handle refused results" do
        @app.expects(:puts).with(regexp_matches(/rspec.+status=refused/))
        @app.process_connect_result("refused", {:sender => "rspec", :statusmsg => "OK"}, (stats = {}), false)
        stats.should == {:connect => [0, 1, 0]}
      end

      it "should correctly handle timeout results" do
        @app.expects(:puts).with(regexp_matches(/rspec.+status=timeout/))
        @app.process_connect_result("timeout", {:sender => "rspec", :statusmsg => "OK"}, (stats = {}), false)
        stats.should == {:connect => [0, 0, 1]}
      end

      it "should support verbose output" do
        @app.expects(:puts).with(regexp_matches(/rspec.+status=timeout.+OK/m))
        @app.process_connect_result("timeout", {:sender => "rspec", :statusmsg => "OK"}, (stats = {}), true)
        stats.should == {:connect => [0, 0, 1]}
      end
    end

    describe "#process_ping_result" do
      it "should track ping stats correctly" do
        @app.expects(:puts).with(regexp_matches(/rspec.+time=1.100/))
        @app.expects(:puts).with(regexp_matches(/rspec.+time=1.200/))
        @app.process_ping_result("1.1", {:sender => "rspec", :statusmsg => "OK"}, (stats = {}), false)
        @app.process_ping_result("1.2", {:sender => "rspec", :statusmsg => "OK"}, stats, false)
        stats.should == {:ping => [1.1, 1.2]}
      end

      it "should support verbose output" do
        @app.expects(:puts).with(regexp_matches(/rspec.+time=1.100.+OK/m))
        @app.process_ping_result("1.1", {:sender => "rspec", :statusmsg => "OK"}, {}, true)
      end
    end

    describe "#print_statistics" do
      it "should support ping statistics" do
        @app.expects(:puts).with(regexp_matches(/Nodes: 2 \/ 2/))
        @app.expects(:puts).with(regexp_matches(/Results: replies=2, maximum=2.000 ms, minimum=1.000 ms, average=1.500 ms/))
        @app.expects(:puts).with(regexp_matches(/Elapsed.+2.00 s/))
        @app.print_statistics({:responses => 2, :noresponsefrom => [], :blocktime => 2}, {:ping => [1.0, 2.0]}, "ping")
      end

      it "should support connect statistics" do
        @app.expects(:puts).with(regexp_matches(/Nodes: 2 \/ 2/))
        @app.expects(:puts).with(regexp_matches(/Results: connected=1, connection refused=0, timed out=1/))
        @app.expects(:puts).with(regexp_matches(/Elapsed.+2.00 s/))
        @app.print_statistics({:responses => 2, :noresponsefrom => [], :blocktime => 2}, {:connect => [1, 0, 1]}, "connect")
      end

      it "should support empty results" do
        @app.expects(:puts).with(regexp_matches(/Results: No responses received/))
        @app.print_statistics({:responses => 2, :noresponsefrom => [], :blocktime => 2}, {}, "ping")
      end
    end

    describe "#main" do
      before do
        @rpc_client = mock
        @rpc_client.expects(:stats).returns(:stats)
        @rpc_client.expects(:progress).returns(false)
        @rpc_client.expects(:verbose).returns(false)
        @app.expects(:rpcclient).returns(@rpc_client)
      end

      it "should handle errors from nodes" do
        @app.expects(:configuration).returns({:action => "ping", :arguments => {:fqdn => "rspec"}}).twice
        @rpc_client.expects(:send).with("ping", {:fqdn => "rspec"}).returns([{:statuscode => 1}])
        @app.expects(:process_ping_result).with("error", {:statuscode => 1}, {}, false)
        @app.expects(:print_statistics).with(:stats, {}, "ping")
        @app.main
      end

      it "should handle ping actions correctly" do
        @app.expects(:configuration).returns({:action => "ping", :arguments => {:fqdn => "rspec"}}).twice
        @rpc_client.expects(:send).with("ping", {:fqdn => "rspec"}).returns([{:statuscode => 0, :data => {}}])
        @app.expects(:print_statistics).with(:stats, {:ping => [0.0]}, "ping")
        @app.main
      end

      it "should handle connect actions correctly" do
        @app.expects(:configuration).returns({:action => "connect", :arguments => {:fqdn => "rspec", :port => 80}}).twice
        @rpc_client.expects(:send).with("connect", {:fqdn => "rspec", :port => 80}).returns([{:statuscode => 0, :data => {:connect => "rspec"}}])
        @app.expects(:print_statistics).with(:stats, {:connect => [0, 0, 0]}, "connect")
        @app.main
      end
    end
  end
end
