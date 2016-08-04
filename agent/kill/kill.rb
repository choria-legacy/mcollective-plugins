module MCollective
    module Agent
        # An agent to kill instances
        #
        # Configuration Options:
        #    kill.halt - Location of halt binary
        #
        class Kill<RPC::Agent
            metadata    :name        => "SimpleRPC Puppet Ubuntu Agent",
                        :description => "Agent to manage puppet the Ubuntu way",
                        :author      => "Marc Cluet",
                        :license     => "Apache License 2.0",
                        :version     => "1.3",
                        :url         => "https://launchpad.net/~canonical-sig/",
                        :timeout     => 30

            def startup_hook
                @halt = config.pluginconf["kill.halt"] || "/sbin/halt"
            end

            # Kills instance
            action "kill" do
                logger.debug ("Killing instance")
                reply[:exitcode] = run("#{@halt}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error killing instance"
                end
            end

            # Kills instance with prejudice
            action "forcekill" do
                logger.debug ("Killing instance through sysrq")
                reply[:exitcode] = run("echo '1' > /proc/sys/kernel/sysrq ; echo 'o' > /proc/sysrq-trigger", :stdout => :output, :stderr => :err, :chomp => true)
                reply[:exitcode] = 0

                # Never expect an answer from this, it's nasty
            end

        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
