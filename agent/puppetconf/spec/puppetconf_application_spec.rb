#!/usr/bin/env rspec
require 'spec_helper'

module MCollective
  describe "puppetconf application" do 
    before do
      application_file = File.join([File.dirname(__FILE__), "../application/puppetconf.rb"])
      @util = MCollective::Test::ApplicationTest.new("puppetconf", :application_file => application_file)
      @app = @util.plugin
    end

    describe "#application_decription" do
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
        }.to raise_error("Action must be environment or server")
      end
    end

    describe "#log" do
      it "should print a log statement with a time" do
        @app.expects(:puts)
        @app.log("foo")
      end
    end

  end
end
