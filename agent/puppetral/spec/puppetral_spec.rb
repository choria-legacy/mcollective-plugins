#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

describe "puppetral agent" do
  before :all do
    @agent = MCollective::Test::LocalAgentTest.new(
      "puppetral",
      :agent_file => File.join([File.dirname(__FILE__), "../agent/puppetral.rb"])
    ).plugin
  end

  describe "#find" do
    before :all do
      @result = @agent.call(:find, :type => 'User', :title => 'bob')
    end

    it "should retrieve information about the type and title passed" do
      @result[:data]['title'].should == "bob"
      @result[:data]['type'].should == "User"
    end

    it "should specify an ensure value for the resource" do
      @result[:data]['parameters'].keys.should include :ensure
    end

    it "should respond with an error if passed an invalid type" do
      @result = @agent.call(:find, :type => 'Foobar', :name => 'Foobaz')

      @result[:statusmsg].should =~ /Could not find type Foobar/
    end
  end

  describe "#search" do
    it "should return a list of all resources of the type passed indexed by resource title" do
      result = @agent.call(:search, :type => 'User')
      result[:statusmsg].should == "OK"
      result[:data].each do |k,v|
        k.class.should == String
        v.keys.should =~ ["exported", "title", "parameters", "tags", "type"]
      end
    end

    it "should respond with an error if passed an invalid type" do
      result = @agent.call(:search, :type => 'Foobar')

      result[:statusmsg].should =~ /Could not find type Foobar/
    end
  end

  describe "#create" do
    before :each do
      @tmpfile = '/tmp/foo'
    end

    after :each do
      File.delete(@tmpfile) if File.exist?(@tmpfile)
    end

    it "should create the resource described and respond with a success message" do
      result = @agent.call(:create, :type => 'file', :title => @tmpfile,
                           :parameters => {:ensure => 'present', :content => "Hello, world!"})
      File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
      result[:data][:output].should == "Resource was created"
    end

    it "should respond with error information if creating the resource fails" do
      badpath = "\\thisisa/bad\\path!!"
      result = @agent.call(:create, :type => 'file', :title => badpath,
                           :parameters => {:ensure => 'present', :content => "Hello, world!"})
      result[:statusmsg].should =~ /File paths must be fully qualified/
      result[:statuscode].should_not == 0
    end

    it "should report an error if the resource was not created" do
      badpath = "/etc/notpermitted"
      result = @agent.call(:create, :type => 'file', :title => badpath,
                           :parameters => {:ensure => 'present', :content => "Hello, world!"})
      result[:data][:output].should == "Resource was not created"
    end

    it "should overwrite an existing resource with the same type and title with different properties" do
      File.open(@tmpfile,'w') { |f| f.puts "Goodbye, cruel world!" }
      result = @agent.call(:create, :type => 'file', :title => @tmpfile,
                           :parameters => {:ensure => 'present', :content => "Hello, world!"})
      File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
    end
  end
end
