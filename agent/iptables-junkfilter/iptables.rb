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
                @timeout = 2
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}
            end

            def handlemsg(msg, connection)
                ret = "unknown command"

                if msg[:body] =~ /^blockip.(\d+\.\d+\.\d+\.\d+)$/
                    ip = $1

                    out = %x[/sbin/iptables -I junk_filter -s #{ip} -j DROP 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'")

                    ret = "Adding #{ip} #{out}"
                elsif msg[:body] =~ /^unblockip.(\d+\.\d+\.\d+\.\d+)$/
                    ip = $1

                    out = %x[/sbin/iptables -D junk_filter -s #{ip} -j DROP 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'")

                    ret = "Removing #{ip} #{out}"
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

            Returned Data
            -------------

            Simple string with some text about the action performed
            EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
