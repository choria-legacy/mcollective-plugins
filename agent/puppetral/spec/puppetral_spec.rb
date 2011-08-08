#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

describe "puppetral agent" do
  before :all do
    @agent = MCollective::Test::LocalAgentTest.new(
      "puppetral",
      :agent_file => File.join([File.dirname(__FILE__), "../puppetral.rb"])
    ).plugin
  end

  describe "#find" do
    before :all do
      @result = @agent.call(:find, :type => 'User', :name => 'bob')
    end

    it "should use Puppet::Resource to find" do
      @result[:statusmsg].should == "OK"
      @result[:statuscode].should == 0
    end

    it "should return data with a resource type and title" do
      @result.should have_data_items('type')
      @result.should have_data_items('title')
    end

    it "should retrieve information about the type and title passed" do
      @result[:data]['title'].should == "bob"
      @result[:data]['type'].should == "User"
    end

    it "should specify an ensure value for the resource" do
      @result[:data]['parameters'].keys.should include :ensure
    end
  end

  describe "#create" do
    before :each do
      @tmpfile = '/tmp/foo'
    end

    after :each do
      File.delete(@tmpfile)
    end

    it "should create the resource described" do
      result = @agent.call(:create, :type => 'File', :path => @tmpfile,
                           :ensure => 'present', :content => "Hello, world!")
      File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
    end

    it "should respond with error information if creating the resource fails" do
      badpath = "this\isnot/apath!"
      result = @agent.call(:create, :type => 'File', :path => badpath,
                           :ensure => 'present', :content => "Hello, world!")
      result[:data][:result].should == "Some error message"
    end

    it "should check whether the resource was actually created" do
      Puppet::Resource.expects(:find).with(['file',@tmpfile].join('/'))
      result = @agent.call(:create, :type => 'File', :path => @tmpfile,
                           :ensure => 'present', :content => "Hello, world!")
    end

    it "should report an error if the resource was not created"

    it "should return 'already exists' if the resource already exists in an identical form" do
      File.open(@tmpfile,'w') { |f| f.puts "Hello, world!" }
      result = @agent.call(:create, :type => 'File', :path => @tmpfile,
                           :ensure => 'present', :content => "Hello, world!")
      result[:data][:result].should == "Resource already exists in specified form."
    end

    it "should overwrite an existing resource with the same type and title with different properties" do
      File.open(@tmpfile,'w') { |f| f.puts "Goodbye, cruel world!" }
      result = @agent.call(:create, :type => 'File', :path => @tmpfile,
                           :ensure => 'present', :content => "Hello, world!")
      File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
    end
  end
end
