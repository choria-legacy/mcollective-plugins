module MCollective
    module Agent
        class Puppetd<RPC::Agent
            def startup_hook
                meta[:license] = "Apache License 2.0"
                meta[:author] = "R.I.Pienaar"
                meta[:version] = "1.2"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 20

                @splaytime = @config.pluginconf["puppetd.splaytime"].to_i || 0
                @lockfile = @config.pluginconf["puppetd.lockfile"] || "/var/lib/puppet/state/puppetdlock"
                @statefile = @config.pluginconf["puppetd.statefile"] || "/var/lib/puppet/state/state.yaml"
                @puppetd = @config.pluginconf["puppetd.puppetd"] || "/usr/sbin/puppetd"
            end

            def enable_action
                enable
            end

            def disable_action
                disable
            end

            def runonce_action
                runonce
            end

            def status_action
                status
            end

            def help
                <<-EOH
                Simple RPC Puppetd Agent
                ========================
    
                Agent to enable, disable and run the puppet agent
    
                ACTIONS:
                    enable, disable, status, runonce

                INPUT:
                    :forcerun   For the runonce action, when set to true this
                                force an immediate run without waiting for any 
                                configured splay

                OUTPUT:
                    :output     A string showing some human parsable status
                    :enabled    for the status action, 1 if the daemon is enabled, 0 otherwise
                    :running    for the status action, 1 if currently running, 0 otherwise

                CONFIGURATION 
                -------------

                puppetd.splaytime - How long to splay for, no splay by default
                puppetd.statefile - Where to find the state.yaml file defaults to
                                    /var/lib/puppet/state/state.yaml
                puppetd.lockfile  - Where to find the lock file defaults to 
                                    /var/lib/puppet/state/puppetdlock
                puppetd.puppetd   - Where to find the puppetd, defaults to 
                                    /usr/sbin/puppetd
                EOH
            end

            private
            def status
                reply[:enabled] = 0
                reply[:running] = 0
                reply[:lastrun] = 0

                if File.exists?(@lockfile)
                    if File::Stat.new(@lockfile).zero?
                        reply[:output] = "Disabled, not running"
		            else
                        reply[:output] = "Enabled, running"
                        reply[:enabled] = 1
                        reply[:running] = 1
		            end
           	    else
                        reply[:output] = "Enabled, not running"
                        reply[:enabled] = 1
                end

                reply[:lastrun] = File.stat(@statefile).mtime.to_i if File.exists?(@statefile)
                reply[:output] += ", last run #{Time.now.to_i - reply[:lastrun]} seconds ago"
            end

            def runonce
                if File.exists?(@lockfile)
                    reply.fail "Lock file exists"
                else
                    if request[:forcerun]
                        reply[:output] = %x[#{@puppetd} --onetime]

                    elsif @splaytime > 0
                        reply[:output] = %x[#{@puppetd} --onetime --splaylimit #{@splaytime} --splay]

                    else
                        reply[:output] = %x[#{@puppetd} --onetime]
                    end
                end
            end

            def enable
                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    if stat.zero?
                        File.unlink(@lockfile)
                        reply[:output] = "Lock removed"
                    else
                        reply[:output] = "Currently runing"
                    end
                else
                    reply.fail "Already unlocked"
                end
            end

            def disable
                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    stat.zero? ? reply.fail("Already disabled") : reply.fail("Currently running")
                else
                    begin
                        File.open(@lockfile, "w") do |file|
                        end

                        reply[:output] = "Lock created"
                    rescue Exception => e
                        reply[:output] = "Could not create lock: #{e}"
                    end
                end
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
