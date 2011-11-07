#! /usr/bin/env ruby
# -*- coding: undecided -*-

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

module MCollective
  describe "packages application" do
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/packages.rb"])
      @util = MCollective::Test::ApplicationTest.new("packages", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_description" do
      it "should have a description set" do
        @app.should have_a_description
      end
    end

    describe "#post_option_parser" do
      it "should raise an exception if action and package are not specified" do
        expect{
          @app.post_option_parser({})
        }.to raise_error("Please specify action and one or more packages")
      end

      it "should raise an exception if action is not uptodate" do
        ARGV << "install"
        ARGV << "package"

        expect{
          @app.post_option_parser({})
        }.to raise_error("Action has to be uptodate")
      end

      it "should set action and packages (without version, release)" do
        ARGV << "uptodate"
        ARGV << "foo"
        ARGV << "bar"
        ARGV << "bazz"

        configuration = {:action => "", :packages => ""}
        @app.post_option_parser(configuration)

        configuration[:action].should == "uptodate"
        configuration[:packages].should == [ { "name" => "foo",  "version" => nil, "release" => nil },
                                              { "name" => "bar",  "version" => nil, "release" => nil },
                                              { "name" => "bazz", "version" => nil, "release" => nil } ]
      end
      it "should set action and packages (without version, release)" do
        ARGV << "uptodate"
        ARGV << "foo/1.0"
        ARGV << "bar"
        ARGV << "bazz/0.14.0SNAPSHOT/201111011659"

        configuration = {:action => "", :"ackages" => ""}
        @app.post_option_parser(configuration)

        configuration[:action].should == "uptodate"
        configuration[:packages].should == [ { "name" => "foo",  "version" => "1.0", "release" => nil },
                                              { "name" => "bar",  "version" => nil, "release" => nil },
                                              { "name" => "bazz", "version" => "0.14.0SNAPSHOT", "release" => "201111011659" } ]
      end
    end

    describe "#validate_configuration" do
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

      it "should return if filter is empty and batch mode is enabled" do
        @app.expects(:options).returns({:filter => nil})
        MCollective::Util.expects(:empty_filter?).returns(true)
        @app.validate_configuration({:batch => true})
      end
    end

    describe "#main" do
      before do
        @rpcclient_mock = mock
      end

      it "should work normal, when response if ok" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil,   "release" => nil}]}
        resp_data = {:packages => [{"name" => "testtool", "version" => "1.0", "release" => "4001.el6", "status" => 0, "tries" => 1}], "status" => 0}
        resp      = {:statuscode => 0, :sender => "node1", :statusmsg => "OK", :data => resp_data}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp])

        @app.expects(:printf).with("%-40s = OK ::: %s :::\n", "node1", resp_data[:packages].inspect)
        @app.main.should == 0
      end

      it "should have exitcode 1 and print ERR, when all response(s) are fail" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        resp_data = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil, "status" => 1, "tries" => 3}], "status" => 1}
        resp      = {:statuscode => 0, :sender => "node1", :statusmsg => "OK", :data => resp_data}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp])

        @app.expects(:printf).with("%-40s = ERR %s ::: %s :::\n", "node1", resp_data["status"], resp_data[:packages].sort.inspect)
        @app.main.should == 1
      end

      it "should have exitcode 1 and print ERR, when one response is fail" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}

        resp1_data = {:packages => [{"name" => "testtool", "version" => "1.0", "release" => "1", "status" => 1, "tries" => 3}], "status" => 0}
        resp1      = {:statuscode => 0, :sender => "node1", :statusmsg => "OK", :data => resp1_data}
        resp2_data = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil, "status" => 1, "tries" => 3}], "status" => 1}
        resp2      = {:statuscode => 0, :sender => "node2", :statusmsg => "OK", :data => resp2_data}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp1, resp2])

        @app.expects(:printf).with("%-40s = OK ::: %s :::\n",     "node1", resp1_data[:packages].inspect)
        @app.expects(:printf).with("%-40s = ERR %s ::: %s :::\n", "node2", resp2_data["status"], resp2_data[:packages].sort.inspect)
        @app.main.should == 1
      end

      it "should work have exitcode 2 and print STATUSCODE, when one statuscode is not ok" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}

        resp_data = {:packages => [{"name" => "testtool", "version" => "1.0", "release" => "1", "status" => 1, "tries" => 3}], "status" => 0}
        resp      = {:statuscode => 1, :sender => "node1", :statusmsg => "OK", :data => resp_data}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp])

        @app.expects(:printf).with("%-40s = STATUSCODE %s\n",     "node1", resp[:statuscode])
        @app.main.should == 2
      end

      it "should work have exitcode 2 and print INVALID, when one response is invalid (missing key)" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}

        resp_data = {:packages => [{"name" => "testtool", "version" => "1.0", "status" => 1, "tries" => 3}], "status" => 0}
        resp      = {:statuscode => 0, :sender => "node1", :statusmsg => "OK", :data => resp_data}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp])

        @app.expects(:printf).with("%-40s = INVALID %s\n", "node1", resp_data.inspect)
        @app.main.should == 2
      end

      it "should work have exitcode 2 and print INVALID, when one response is invalid (packages missing)" do
        cmdline_args = {:action => "uptodate", :packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}
        @app.stubs(:configuration).returns(cmdline_args)
        @app.expects(:rpcclient).with("packages", :options => nil).returns(@rpcclient_mock)

        send_args = {:packages => [{"name" => "testtool", "version" => nil, "release" => nil}]}

        resp      = {:statuscode => 0, :sender => "node1", :statusmsg => "OK", :data => nil}

        @rpcclient_mock.expects(:send).with("uptodate", send_args).returns([resp])

        @app.expects(:printf).with("%-40s = INVALID %s\n", "node1", nil.inspect)
        @app.main.should == 2
      end
    end
  end
end
