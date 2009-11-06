require 'socket'

module MCollective
    module Agent
        # An agent that manipulates a chain called 'junkfilter' with iptables
        #
        # See http://code.google.com/p/mcollective-plugins/wiki/AgentIptablesJunkfilter
        #
        # Released under the terms of the GPL
        class Iptables
            attr_reader :timeout, :meta

            def initialize
                @log = MCollective::Log.instance
                @config = MCollective::Config.instance

                @timeout = 2
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}
            end

            def handlemsg(msg, connection)
                ret = "unknown command"
                
                if @config.pluginconf.include?("iptables.target")
                    target = @config.pluginconf["iptables.target"]
                else
                    target = "DROP"
                end


                if msg[:body] =~ /^block.(\d+\.\d+\.\d+\.\d+)$/
                    ip = $1

                    out = %x[/sbin/iptables -A junk_filter -s #{ip} -j #{target} 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'")

                    ret = "Adding #{ip} #{out}"
                elsif msg[:body] =~ /^unblock.(\d+\.\d+\.\d+\.\d+)$/
                    ip = $1

                    out = %x[/sbin/iptables -D junk_filter -s #{ip} -j #{target} 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'")

                    ret = "Removing #{ip} #{out}"
                elsif msg[:body] =~ /^isblocked.(\d+\.\d+\.\d+\.\d+)$/
                    ip = $1

                    matches = %x[/sbin/iptables -L junk_filter -n 2>&1].split("\n").grep(/^#{target}.+#{ip}/).size

                    matches >= 1 ? ret = true : ret = false

                    @log.debug("isblocked #{ip} returning #{ret}")
                end

                ret
            end

            def help
            <<-EOH
            Iptables Agent
            ==============

            Agent to add and remove ip addresses from the junk_filter chain in iptables

            Accepted Messages
            -----------------
            blockip <ip>   - Adds the IP address to the filter
            unblock <ip>   - Removes the IP address from the filter
            blocked? <ip>  - Checks if an ip is blocked, returns true or false

            Returned Data
            -------------

            Usually a simple string with some text about the action performed
            except in the case of blocked? which will return true or false
            EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
