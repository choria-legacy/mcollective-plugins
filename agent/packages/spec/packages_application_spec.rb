#! /usr/bin/env ruby

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

        configuration = {:action => "", :package => ""}
        @app.post_option_parser(configuration)

        configuration[:action].should == "uptodate"
        configuration[:packages].should == [ { :name => "foo",  :version => nil, :release => nil },
                                             { :name => "bar",  :version => nil, :release => nil },
                                             { :name => "bazz", :version => nil, :release => nil } ]
      end
      it "should set action and packages (without version, release)" do
        ARGV << "uptodate"
        ARGV << "foo/1.0"
        ARGV << "bar"
        ARGV << "bazz/0.14.0SNAPSHOT/201111011659"

        configuration = {:action => "", :package => ""}
        @app.post_option_parser(configuration)

        configuration[:action].should == "uptodate"
        configuration[:packages].should == [ { :name => "foo",  :version => "1.0", :release => nil },
                                             { :name => "bar",  :version => nil, :release => nil },
                                             { :name => "bazz", :version => "0.14.0SNAPSHOT", :release => "201111011659" } ]
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
  end
end
