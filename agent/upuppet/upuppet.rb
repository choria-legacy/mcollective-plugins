module MCollective
    module Agent
        # An agent to manage puppet the Ubuntu way
        #
        # Configuration Options:
        #    upuppet.puppetd - Location of puppet binary
        #
        class Upuppet<RPC::Agent
            metadata    :name        => "SimpleRPC Puppet Ubuntu Agent",
                        :description => "Agent to manage puppet the Ubuntu way",
                        :author      => "Marc Cluet",
                        :license     => "Apache License 2.0",
                        :version     => "1.3",
                        :url         => "https://launchpad.net/~canonical-sig/",
                        :timeout     => 1000

            def startup_hook
                @puppetd = config.pluginconf["upuppet.puppetd"] || "/usr/sbin/puppetd"
            end

            # Starts puppet
            action "start" do
                logger.debug ("Starting Puppet Service")
                reply[:exitcode] = run("service puppet start", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error starting Puppet."
                end
            end

            # Stops puppet
            action "stop" do
                logger.debug ("Stopping Puppet Service")
                reply[:exitcode] = run("service puppet stop", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error stopping Puppet"
                end
            end

            # Restart puppet
            action "restart" do
                logger.debug ("Restarting Puppet Service")
                reply[:exitcode] = run("service puppet restart", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error restarting Puppet"
                end
            end

            # Reads a fact
            action "cycle_run" do
                if request[:numtimes].nil?
                    numtimes = 3
                else
                    numtimes = Integer(request[:numtimes])
                end
                logger.debug ("Cycle running puppet #{numtimes} times")
                counter = 1
                null = %x[service puppet stop]
                while counter <= numtimes
                    logger.debug ("Cycle running puppet: #{counter} LOOP")
                    reply[:exitcode] = run("#{@puppetd} --test --color=none --summarize", :stdout => :stdout, :stderr => :err, :chomp => true)
                    counter+=1
                end
                null = %x[service puppet start]
                reply[:output] = "OK"
                reply[:exitcode] = 0
            end

        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
