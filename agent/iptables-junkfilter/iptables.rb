require 'socket'

module MCollective
    module Agent
        # An agent that manipulates a chain called 'junkfilter' with iptables
        #
        # See http://code.google.com/p/mcollective-plugins/wiki/AgentIptablesJunkfilter
        #
        # Released under the terms of the GPL
        class Iptables<RPC::Agent
            def startup_hook
                meta[:license] = "GPLv2"
                meta[:author] = "R.I.Pienaar <rip@devco.net>"
                meta[:version] = "1.1"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 2
            end

            def block_action
                validate :ipaddr, :ipv4address

                blockip(request[:ipaddr])
            end

            def unblock_action
                validate :ipaddr, :ipv4address

                unblockip(request[:ipaddr])
            end

            def isblocked_action
                validate :ipaddr, :ipv4address

                isblocked(request[:ipaddr])
            end

            def help
                <<-EOH
                Iptables Agent
                ==============
    
                Agent to add and remove ip addresses from the junk_filter chain in iptables
    
                ACTIONS:
                    block, unblock, isblocked

                INPUT:
                    :ipaddr     the address to block

                OUTPUT:
                    :output     output from iptables if relevant else a short status message
    
                EOH
            end

            private
            # Deals with requests to block an ip
            def blockip(ip)
                logger.debug("Blocking #{ip} with target #{target}")

                # if he's already blocked we just dont bother doing it again
                unless isblocked?(ip)
                    out = %x[/sbin/iptables -A junk_filter -s #{ip} -j #{target} 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'")
                else
                    reply.fail "#{ip} was already blocked"
                    return
                end
    
                if isblocked?(ip)
                    unless out == ""
                        reply[:output] = out
                    else
                        reply[:output] = "#{ip} was blocked"
                    end
                else
                    reply.fail "Failed to add #{ip}: #{out}"
                end
            end
    
            # Deals with requests to unblock an ip
            def unblockip(ip)
                logger.debug("Unblocking #{ip} with target #{target}")

                out = ""

                # remove it if it's blocked
                if isblocked?(ip)
                    out = %x[/sbin/iptables -D junk_filter -s #{ip} -j #{target} 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'")
                else
                    reply.fail "#{ip} was already unblocked"
                    return
                end
    
                # check it was removed
                if isblocked?(ip)
                    reply.fail "IP left blocked, iptables says: #{out}"
                else
                    unless out == ""
                        reply[:output] = out
                    else
                        reply[:output] = "#{ip} was unblocked"
                    end
                end
            end
    
            # Deals with requests for status of a ip
            def isblocked(ip)
                if isblocked?(ip)
                    reply[:output] = "#{ip} is blocked"
                else
                    reply[:output] = "#{ip} is not blocked"
                end
            end
    
            # Utility to figure out if a ip is blocked or not, just return true or false
            def isblocked?(ip)
                logger.debug("Checking if #{ip} is blocked with target #{target}")

                matches = %x[/sbin/iptables -L junk_filter -n 2>&1].split("\n").grep(/^#{target}.+#{ip}/).size
    
                matches >= 1 
            end
    
            # Returns the target to use for rules
            def target
                target = "DROP"
    
                if @config.pluginconf.include?("iptables.target")
                    target = @config.pluginconf["iptables.target"]
                end
    
                target
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
