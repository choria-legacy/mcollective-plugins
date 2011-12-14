#!/usr/bin/env rspec
require 'spec_helper'

describe "puppetca agent" do
  before do
    agent_file = File.join([File.dirname(__FILE__), "../agent/puppetca.rb"])
    @agent = MCollective::Test::LocalAgentTest.new("puppetca", :agent_file => agent_file).plugin
  end

  describe "#meta" do
    it "should have valid metadata" do
      @agent.should have_valid_metadata
    end
  end

  describe "#clean" do
    it "should remove signed certs if they exist" do
      @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(true)
      File.expects(:unlink).with("signed")

      @agent.expects(:cert_waiting?).with("certname").returns(false)
      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"Removed signed cert: signed.")
    end

    it "should remove unsigned certs if they exist" do
      @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(false)

      @agent.expects(:cert_waiting?).with("certname").returns(true)
      File.expects(:unlink).with("request")

      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"Removed csr: request.")
    end

    it "should fail if there are no certs to delete" do
      @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(false)

      result = @agent.call(:clean, :certname => "certname")
      result.should be_aborted_error
      result[:statusmsg].should == "Could not find any certs to delete"
    end

    it "should return the message if there are no certs but msg.size is not 0" do
      @agent.expects(:paths_for_cert).with("certname").twice.returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(false)
      Array.any_instance.expects(:size).returns(1)
      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg => "")
    end
  end
  describe "#revoke" do
    it "should revoke a cert" do
      @agent.expects(:run).with(" --color=none --revoke 'certname'", :stdout => :output, :chomp => true).returns("true")
      result = @agent.call(:revoke, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:out => "true")
    end
  end

  describe "sign" do
    it "should fail if the cert has already been signed" do
      @agent.expects(:has_cert?).with("certname").returns(true)
      result = @agent.call(:sign, :certname => "certname")
      result.should be_aborted_error
      result[:statusmsg] = "Already have a cert for certname not attempting to sign again"
    end

    it "should fail if there are no certs to sign" do
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(false)
      result = @agent.call(:sign, :certname => "certname")
      result.should be_aborted_error
      result[:statusmsg].should == "No cert found to sign"
    end

    it "should sign a cert if there is one waiting" do
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(true)
      @agent.expects(:run).with(" --color=none --sign 'certname'", :stdout => :output, :chomp => true).returns("true")
      result = @agent.call(:sign, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:out => "true")
    end
  end

  describe "list" do
    it "should list all certs, signed and waiting" do
      Dir.expects(:entries).with("/requests").returns(["requested.pem"])
      Dir.expects(:entries).with("/signed").returns(["signed.pem"])
      result = @agent.call(:list)
      result[:data].should == {:requests=>["requested"], :signed=>["signed"]}
      result.should be_successful
      result.should have_data_items(:signed=>["signed"], :requests=>["requested"])
    end
  end

  describe "status" do
    it "should say so if the cert is signed" do
      @agent.expects(:has_cert?).with("certname").returns(true)

      result = @agent.call(:status, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"signed")
    end

    it "should say so if the cert is awaiting signature" do
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(true)

      result = @agent.call(:status, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"awaiting signature")
    end

    it "should say so if the cert is not found" do
      @agent.expects(:has_cert?).with("certname").returns(false)
      @agent.expects(:cert_waiting?).with("certname").returns(false)

      result = @agent.call(:status, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"not found")
    end
  end

  describe "has_cert" do
    it "should return true if we have a signed cert matching certname" do
      @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
      File.expects(:exist?).with("signed").returns(true)
      File.expects(:unlink).with("signed")
      @agent.expects(:cert_waiting?).returns(false)
      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"Removed signed cert: signed.")
    end

    it "should return false if we have a signed cert matching certname" do
      @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
      File.expects(:exist?).with("signed").returns(false)
      @agent.expects(:cert_waiting?).returns(false)
      result = @agent.call(:clean, :certname => "certname")
      result.should be_aborted_error
      result[:statusmsg].should == "Could not find any certs to delete"
    end
  end

  describe "cert_waiting" do
    it "should return true if there is a signing request waiting" do
      @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(false)
      File.expects(:exist?).with("request").returns(true)
      File.expects(:unlink).with("request")
      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"Removed csr: request.")
    end

    it "should return true if there is a signing request waiting" do
      @agent.stubs(:paths_for_cert).with("certname").returns({:signed => "signed", :request => "request"})
      @agent.expects(:has_cert?).with("certname").returns(false)
      File.expects(:exist?).with("request").returns(false)
      result = @agent.call(:clean, :certname => "certname")
      result.should be_aborted_error
      result[:statusmsg].should == "Could not find any certs to delete"
    end
  end

  describe "paths_for_cert" do
    it "should return get paths to all files involged with a cert" do
      @agent.expects(:has_cert?).with("certname").returns(false)
      File.expects(:exist?).with("/requests/certname.pem").returns(true)
      File.expects(:unlink).with("/requests/certname.pem")
      result = @agent.call(:clean, :certname => "certname")
      result.should be_successful
      result.should have_data_items(:msg=>"Removed csr: /requests/certname.pem")
    end
  end
end
