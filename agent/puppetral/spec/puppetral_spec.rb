#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

describe "puppetral agent" do
    before do
        @agent = MCollective::Test::LocalAgentTest.new(
          "puppetral", 
          :agent_file => File.join([File.dirname(__FILE__), "../puppetral.rb"])
        ).plugin
    end

    describe "#find" do
        it "should use Puppet::Resource to find" do
            result = @agent.call(:find, :type => 'User', :name => 'bob')
            result[:statusmsg].should == "OK"
            result[:statuscode].should == 0
            result.should have_data_items('title' => 'bob')
            result[:data][:result]['title'].should == "bob"
            result[:data][:result]['type'].should == "User"
            result[:data][:result]['parameters'].keys.should include :ensure
        end
    end

    describe "#create" do
        it "should create the resource described" do
            tmpfile = '/tmp/foo'
            result = @agent.call(:create, :type => 'File' )
        end
    end
end
