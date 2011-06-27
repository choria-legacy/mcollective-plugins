#! /usr/bin/env ruby

require File.join([File.dirname(__FILE__), '/../../../spec/spec_helper'])

describe "puppetd agent" do
    before do
        agent_file = File.join([File.dirname(__FILE__), "../agent/puppetd.rb"])
        @agent = MCollective::Test::LocalAgentTest.new("puppetd", :agent_file => agent_file).plugin
        @agent.instance_variable_set("@lockfile", "spec_test_lock_file")
    end

    describe "#meta" do
        it "should have valid metadata" do
            @agent.should have_valid_metadata
        end
    end

    describe "#last_run_summary" do
        it "should return the last run summary" do
            @agent.instance_variable_set("@last_summary", "spec_test_last_summary")
            YAML.expects(:load_file).with("spec_test_last_summary").returns({"time" => nil, "events" => nil, "changes" => nil, "resources" => {"failed" => 0,"changed" => 0, "total" => 0, "restarted" => 0, "out_of_sync" => 0}})

            result = @agent.call(:last_run_summary)
            result.should be_successful
            result.should have_data_items({:changes => nil,
                                           :events => nil,
                                           :resources => {"failed"=>0,
                                                          "changed"=>0,
                                                          "total"=>0,
                                                          "restarted"=>0,
                                                          "out_of_sync"=>0},
                                           :time => nil})
        end
    end

    describe "#enable" do
        it "should fail if the lockfile doesn't exist" do
            File.expects(:exists?).returns(false)
            result = @agent.call(:enable)
            result.should be_aborted_error
            result[:statusmsg].should == "Already unlocked"
        end

        it "should attempt to remove zero byte lockfiles" do
            stat = mock
            stat.stubs(:zero?).returns(true)

            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)
            File.expects(:exists?).with("spec_test_lock_file").returns(true)
            File.expects(:unlink).with("spec_test_lock_file").returns(true)

            result = @agent.call(:enable)
            result.should be_successful
            result.should have_data_items(:output=>"Lock removed")
        end

        it "should not remove lock files for running puppetds" do
            stat = mock
            stat.stubs(:zero?).returns(false)

            File.expects(:exists?).with("spec_test_lock_file").returns(true)
            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)

            result = @agent.call(:enable)
            result.should have_data_items(:output=>"Currently runing")
        end
    end

    describe "#disable" do
        it "should fail if puppetd is already disabled" do
            stat = mock
            stat.stubs(:zero?).returns(true)

            File.expects(:exists?).returns(true)
            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)

            result = @agent.call(:disable)
            result.should be_aborted_error
            result[:statusmsg].should == "Already disabled"
        end

        it "should fail if puppetd is running" do
            stat = mock
            stat.stubs(:zero?).returns(false)

            File.expects(:exists?).returns(true)
            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)

            result = @agent.call(:disable)
            result.should be_aborted_error
            result[:statusmsg].should == "Currently running"
        end

        it "should create the lock if the lockfile doesn't exist" do
            File.expects(:exists?).returns(false)
            File.expects(:open).with("spec_test_lock_file", "w").yields(nil)

            result = @agent.call(:disable)
            result.should have_data_items(:output=>"Lock created")
        end

        #Note, this test will not pass until the puppetd agent's
        #disable method fails on a raised exception
        it "should raise an exception if the file cannot be written" do
            File.expects(:exists?).returns(false)
            File.expects(:open).with("spec_test_lock_file", "w").raises("foo")

            result = @agent.call(:disable)
            result.should be_aborted_error
            result[:statusmsg].should == "Could not create lock: foo"
        end
    end

    describe "#runonce" do
        it "is already running" do
            File.expects(:exists?).with("spec_test_lock_file").returns(true)
            result = @agent.call(:runonce)
            result.should be_aborted_error
            result[:statusmsg].should == "Lock file exists, puppetd is already running or it's disabled"
        end

        it "runs puppet if it is not already running, with splaytime if request[:forcerun] is true" do
            @agent.instance_variable_set("@puppetd", "spec_test_puppetd")
            @agent.instance_variable_set("@splaytime", 1)

            @agent.expects(:run).with("spec_test_puppetd --onetime --splaylimit 1 --splay", :stdout => :output, :chomp => true)

            result = @agent.call(:runonce)
            result.should be_successful

        end

        it "runs puppet if it is not already running, without splaytime if require[:forcerun] is false" do
            @agent.instance_variable_set("@puppetd", "spec_test_puppetd")

            @agent.expects(:run).with("spec_test_puppetd --onetime", :stdout => :output, :chomp => true)

            result = @agent.call(:runonce, :forcerun => true)
            result.should be_successful
        end

    end

    describe "#status" do
        it "is disabled when the lockfile exists and its size is 0" do
            stat = mock
            stat.stubs(:zero?).returns(true)
            @agent.instance_variable_set("@statefile", "spec_test_state_file")

            File.expects(:exists?).with("spec_test_lock_file").returns(true)
            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)
            File.expects(:exists?).with("spec_test_state_file").returns(false)

            result = @agent.call(:status)
            result.should be_successful
            result.should have_data_items({:running => 0,
                                           :enabled => 0,
                                           :lastrun => 0,
                                           :output => /Disabled, not running, last run/})

        end

        it "is enabled and running when the lockfile exists and its size is not 0" do
            stat = mock
            stat.stubs(:zero?).returns(false)
            @agent.instance_variable_set("@statefile", "spec_test_state_file")

            File.expects(:exists?).with("spec_test_lock_file").returns(true)
            File::Stat.expects(:new).with("spec_test_lock_file").returns(stat)
            File.expects(:exists?).with("spec_test_state_file").returns(false)

            result = @agent.call(:status)
            result.should be_successful
            result.should have_data_items({:running => 1,
                                           :enabled => 1,
                                           :lastrun => 0,
                                           :output => /Enabled, running, last run/})
        end

        it "is enabled and not running if the lockfile does not exist" do
            File.expects(:exists?).with("spec_test_lock_file").returns(false)
            File.expects(:exists?).with("spec_test_state_file").returns(false)
            @agent.instance_variable_set("@statefile", "spec_test_state_file")

            result = @agent.call(:status)
            result.should be_successful
            result.should have_data_items({:running => 0,
                                           :enabled => 1,
                                           :lastrun => 0,
                                           :output => /Enabled, not running, last run/})
        end
    end
end
