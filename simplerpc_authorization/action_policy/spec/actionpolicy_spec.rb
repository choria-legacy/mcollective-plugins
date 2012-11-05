#!/usr/bin/env rspec
require 'spec_helper'
require File.join(File.dirname(__FILE__), '../', 'actionpolicy.rb')

module MCollective
  module Util
    describe ActionPolicy do

      describe '#authorize' do
        let(:config){mock}
        let(:request){mock}
        let(:pluginconf){mock}
        let(:policyfile){
          ["policy default deny", "allow\t*\t*\t*\t*"]
        }

        before :each do
          Log.stubs(:debug)
          Config.stubs(:instance).returns(config)
          config.stubs(:configdir).returns("/tmp")
          config.stubs(:pluginconf).returns(pluginconf)
          request.stubs(:agent).returns("test_agent")
        end

        it "should return true if the policy file exists and the policy evals to true" do
          pluginconf.stubs(:include?).returns(true)
          pluginconf.stubs(:fetch).returns('1')
          File.stubs(:exist?).with('/tmp/policies/test_agent.policy').returns(true)
          File.stubs(:open).returns(policyfile)
          ActionPolicy.expects(:check_policy).returns(true)
          ActionPolicy.authorize(request).should == true
        end

        it "should return true if the default policy is true" do
          pluginconf.stubs(:include?).returns(true)
          pluginconf.stubs(:fetch).returns('1')
          File.stubs(:exists?).returns(false)
          ActionPolicy.authorize(request).should == true
        end

        it "should load the default policy file if one is specified and a specific agent policy file does not exist" do
          pluginconf.stubs(:include?).returns(true)
          pluginconf.stubs(:fetch).returns('1')
          pluginconf.expects(:fetch).with("actionpolicy.default_name", "default").returns("default")
          File.expects(:exist?).with("/tmp/policies/test_agent.policy").returns(false)
          File.expects(:exist?).with("/tmp/policies/default.policy").returns(true)
          File.stubs(:open).returns(policyfile)
          ActionPolicy.expects(:check_policy).returns(true)
          ActionPolicy.authorize(request).should == true
        end

        it "should call deny if the default policy is false" do
          pluginconf.stubs(:include?).returns(:false)
          pluginconf.stubs(:fetch).returns('0')
          File.stubs(:exists?).returns(false)
          ActionPolicy.expects(:deny)
          ActionPolicy.authorize(request)
        end
      end

      describe '#eval_statement' do
        it "should return a logical operator if the token is a logical operator" do
          ActionPolicy.eval_statement({"and" => "and"}, 'all').should == "and"

        end

        it "should evaluate the truth value of a fact statement in a fact list" do
          Util.expects(:get_fact).with('foo').returns('bar')
          ActionPolicy.eval_statement({'statement' => 'foo=bar'}, 'fact').should == true
        end

        it "should evaluate the truth value of a class statement in a class list" do
          Util.expects(:has_cf_class?).with("apache").returns(true)
          ActionPolicy.eval_statement({'statement' => 'apache'}, 'class').should == true
        end

        it "should evaulate the truth value of a data function" do
          Matcher.expects(:eval_compound_fstatement).returns(true)
          ActionPolicy.eval_statement({'fstatement' => {:name => 'apache'}}, 'all').should == true
        end

        it "should evaluate the truth value of a fact and class statement in a all list" do
          Util.expects(:get_fact).with('foo').returns('bar')
          Util.expects(:has_cf_class?).with("apache").returns(true)
          ActionPolicy.eval_statement({'statement' => 'foo=bar'}, 'all').should == true
          ActionPolicy.eval_statement({'statement' => 'apache'}, 'all').should == true
        end

        it "should fail if trying to evaluate a fact statement in a class list" do
          expect{
            ActionPolicy.eval_statement({'statement' => 'foo=bar'}, 'class')
          }.to raise_error
        end

        it "should fail if trying to evaluate a class statement in a fact list" do
          expect{
            ActionPolicy.eval_statement({'statement' => 'apache'}, 'fact')
          }.to raise_error
        end

        it "should fail if the data function cannot evaluate" do
          Matcher.expects(:eval_compound_fstatement).raises('error')
          ActionPolicy.expects(:deny)
          ActionPolicy.eval_statement({'fstatement' => {:name => 'apache'}}, 'all')
        end

      end

      describe '#is_compound?' do
        it "should return true if the statement is naturally compound" do
          ActionPolicy.is_compound?('foo and bar').should == true
        end

        it "should return true if the statement only contains a Data function" do
          ActionPolicy.is_compound?('foo("value").othervalue=thevalue').should == true
        end

        it "should return false if the statement is not compound in a facts list" do
          ActionPolicy.is_compound?('foo=bar bar=foo').should == false
        end

        it "should return false if the statement is not compound in a class list" do
          ActionPolicy.is_compound?('apache::install /foo/').should == false
        end
      end

      describe '#parse_command' do
        before :each do
          MCollective::Matcher.expects(:create_compound_callstack).returns([''])
        end
        it "should correctly parse a 'fact' list" do
          ActionPolicy.expects(:eval_statement).with('', 'fact').returns(true)
          result = ActionPolicy.parse_compound([''], 'fact')
          result.should == true
        end

        it "should correctly parse a 'class' list" do
          ActionPolicy.expects(:eval_statement).with('', 'class').returns(true)
          result = ActionPolicy.parse_compound([''], 'class')
          result.should == true
        end

        it "should correctly parse an 'all' list" do
          ActionPolicy.expects(:eval_statement).with('', 'all').returns(false)
          result = ActionPolicy.parse_compound([''], 'all')
          result.should == false
        end
      end

      describe '#check_policy' do
        let(:request) do
          mock
        end

        before :each do
          request.stubs(:caller).returns('caller')
          request.stubs(:action).returns('action')
        end
        it "should return true if lists pass and auth is set to allow" do
          ActionPolicy.check_policy('allow', 'caller', '*', '*', '*', request, 'file', 1).should == true
        end

        it "should call deny if lists pass and auth is not set to allow" do
          ActionPolicy.expects(:deny)
          ActionPolicy.check_policy('deny', 'caller', '*', '*', '*', request, 'file', 1)
        end

        it "should calculate the truth value of all non compound facs" do
          Util.expects(:get_fact).with("foo").returns("bar")
          ActionPolicy.check_policy('allow', 'caller', '*', 'foo=bar', '*', request, 'file', 1).should == true
        end

        it "should calculate the truth value of all non compound classes" do
          Util.expects(:has_cf_class?).with("apache").returns(true)
          ActionPolicy.check_policy('allow', 'caller', '*', '*', 'apache', request, 'file', 1).should == true
        end

        it "should calculate the truth value of compound fact lists" do
          Util.expects(:get_fact).with("v1").returns("r1")
          Util.expects(:get_fact).with("v2").returns("r2")

          ActionPolicy.check_policy('allow', 'caller', '*', 'v1=r1 and v2=r2', '*', request, 'file', 1).should == true
        end

        it "should calculate the truth value of compound class lists" do
          Util.expects(:has_cf_class?).with("apache").returns(true)
          Util.expects(:has_cf_class?).with("apache::install").returns(true)
          ActionPolicy.check_policy('allow', 'caller', '*', '*', 'apache and apache::install', request, 'file', 1).should == true
        end

        it "should calculate the truth value of a mixed list" do
          Util.expects(:get_fact).with("foo").returns("bar")
          Util.expects(:has_cf_class?).with("apache").returns(true)
          ActionPolicy.check_policy('allow', 'caller', '*', 'foo=bar and apache', nil, request, 'file', 1).should == true
        end

        it "should pass all wildcard facts and classes" do
          ActionPolicy.check_policy('allow', '*', '*', '*', '*', request, 'file', 1).should == true
        end

        it "should allow all wildcard callers" do
          ActionPolicy.check_policy('allow', '*', '*', '*', '*', request, 'file', 1).should == true
        end

        it "should allow all wildcard actions" do
          ActionPolicy.check_policy('allow', '*', '*', '*', '*', request, 'file', 1).should == true
        end

        it "should return false if the caller is not in the allowed list of callers" do
          ActionPolicy.check_policy('allow', 'caller2', '*', '*', '*', request, 'file', 1).should == false
        end

        it "should return false if the action is not included in the action list" do
          ActionPolicy.check_policy('allow', '*', 'action2', '*', '*', request, 'file', 1).should == false
        end

      end

      describe '#deny' do
        it "should log an error and raise an exception" do
          log = mock
          Log.expects(:debug).with('message')

          expect{
            ActionPolicy.deny('message')
          }.to raise_error RPCAborted
        end
      end
    end
  end
end
