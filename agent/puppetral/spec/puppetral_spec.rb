#!/usr/bin/env rspec
require 'spec_helper'

describe "puppetral agent" do
  before :all do
    agent_file = File.join([File.dirname(__FILE__), "../agent/puppetral.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("puppetral", :agent_file => agent_file).plugin
  end

  describe "#find" do
    it "should retrieve information about the type and title passed" do
      result = @agent.call(:find, :type => 'User', :title => 'bob')
      result[:data]['title'].should == "bob"
      result[:data]['type'].should == "User"
    end

    it "should specify an ensure value for the resource" do
      result = @agent.call(:find, :type => 'User', :title => 'bob')
      result[:data]['parameters'].keys.should include :ensure
    end

    it "should respond with an error if passed an invalid type" do
      result = @agent.call(:find, :type => 'Foobar', :title => 'Foobaz')
      result[:statusmsg].should =~ /Could not find type Foobar/
    end

    it "should prune parameters from the result" do
      result = @agent.call(:find, :type => 'User', :title => 'root')
      result[:data]["parameters"].should_not have_key(:loglevel)
    end

    it "should leave the provider parameter on the result when looking up packages" do
      result = @agent.call(:find, :type => 'Package', :title => 'rspec')
      result[:data]['parameters'].should have_key(:provider)
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

    def group_with_gid(gid)
      [
        stub({
          :to_pson_data_hash => {
            "exported"   => false,
            "title"      => "wheel",
            "tags"       => ["group", "wheel"],
            "type"       => "Group",
            "parameters" => {
              :provider             => :directoryservice,
              :attribute_membership => :minimum,
              :auth_membership      => true,
              :loglevel             => :notice,
              :ensure               => :present,
              :members              => ["root"],
              :gid                  => gid
            }
          }
        })
      ]
    end
    describe "when avoiding conflicts" do
      it "should remove the passed parameter if there is a conflict with it" do
        Puppet::Resource.expects(:new).with('group', 'testgroup', :parameters => {:ensure=>'present'})
        Puppet::Resource.indirection.expects(:save).returns({:ensure=>:present})
        Puppet::Resource.indirection.expects(:search).with('group', {}).returns(group_with_gid(0))
        result = @agent.call(:create, :type => 'group', :title => 'testgroup',
                             :parameters => {:ensure => 'present', :gid => "0"}, :avoid_conflict => :gid)
      end

      it "should remove the passed parameter if there is a resource with a conflicting title" do
        Puppet::Resource.expects(:new).with('group', 'wheel', :parameters => {:ensure=>'present'})
        Puppet::Resource.indirection.expects(:save).returns({:ensure=>:present})
        Puppet::Resource.indirection.expects(:search).with('group', {}).returns(group_with_gid(2))
        result = @agent.call(:create, :type => 'group', :title => 'wheel',
                             :parameters => {:ensure => 'present', :gid => "0"}, :avoid_conflict => :gid)
      end

      it "should do nothing if there is no conflict" do
        Puppet::Resource.expects(:new).with('group', 'testgroup', :parameters => {:ensure=>'present', :gid => '555'})
        Puppet::Resource.indirection.expects(:save).returns({:ensure=>:present})
        Puppet::Resource.indirection.expects(:search).with('group', {}).returns(group_with_gid(0))
        result = @agent.call(:create, :type => 'group', :title => 'testgroup',
                             :parameters => {:ensure => 'present', :gid => "555"}, :avoid_conflict => :gid)
      end
    end

    describe "when not avoiding conflicts" do
      it "should create the resource described and respond with a success message" do
        result = @agent.call(:create, :type => 'file', :title => @tmpfile,
                             :parameters => {:ensure => 'present', :content => "Hello, world!"})
        File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
        result[:data][:status].should == "Resource was created"
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
        result[:data][:status].should =~ /change from absent to present failed/
      end

      it "should overwrite an existing resource with the same type and title with different properties" do
        File.open(@tmpfile,'w') { |f| f.puts "Goodbye, cruel world!" }
        result = @agent.call(:create, :type => 'file', :title => @tmpfile,
                             :parameters => {:ensure => 'present', :content => "Hello, world!"})
        File.open(@tmpfile, 'r') { |f| f.read.should == "Hello, world!" }
      end
    end
  end
end
