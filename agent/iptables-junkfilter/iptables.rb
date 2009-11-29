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
                @log = Log.instance
                @config = Config.instance

                @timeout = 2
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}
            end

            def handlemsg(msg, connection)
                ip = msg[:body]["ip"]
                command = msg[:body]["command"]

                ret = {"status" => false,
                       "output" => "unknown command"}
                
                case command
                    when "block"
                        ret = blockip(ip)

                    when "unblock"
                        ret = unblockip(ip)

                    when "isblocked"
                        ret = isblocked(ip)
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
                Input is a hash of command and ip, commands can be:
    
                block      - Adds the IP address to the filter
                unblock    - Removes the IP address from the filter
                isblocked  - Checks if an ip is blocked
    
                Input hash should be:
    
                {"command" => "block",
                 "ip"      => "192.168.1.1"}
    
                Returned Data
                -------------
    
                Returned data is a hash, status is boolean indicating success of the request 
                while the output is just some pretty text.
    
                {"status" => false
                 "output" => "Failed to add 1.2.3.4: <ip tables output>"}
    
                EOH
            end

            private
            # Deals with requests to block an ip
            def blockip(ip)
                @log.debug("Blocking #{ip} with target #{target}")

                # if he's already blocked we just dont bother doing it again
                unless isblocked?(ip)
                    out = %x[/sbin/iptables -A junk_filter -s #{ip} -j #{target} 2>&1]
                    system("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'")
                end
    
                ret = {}
    
                if isblocked?(ip)
                    ret["status"] = true
                    ret["output"] = out
                else
                    ret["status"] = false
                    ret["output"] = "Failed to add #{ip}: #{out}"
                end
    
                ret
            end
    
            # Deals with requests to unblock an ip
            def unblockip(ip)
                @log.debug("Unblocking #{ip} with target #{target}")

                out = %x[/sbin/iptables -D junk_filter -s #{ip} -j #{target} 2>&1]
                system("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'")
    
                ret = {}
    
                if isblocked?(ip)
                    ret["status"] = false
                    ret["output"] = "IP left blocked, iptables says: #{out}"
                else
                    ret["status"] = true
                    ret["output"] = out
                end
    
                ret
            end
    
            # Deals with requests for status of a ip
            def isblocked(ip)
                ret = {}
    
                if isblocked?(ip)
                    ret["status"] = true
                    ret["output"] = ""
                else
                    ret["status"] = false
                    ret["output"] = ""
                end
    
                ret
            end
    
            # Utility to figure out if a ip is blocked or not, just return true or false
            def isblocked?(ip)
                @log.debug("Checking if #{ip} is blocked with target #{target}")

                matches = %x[/sbin/iptables -L junk_filter -n 2>&1].split("\n").grep(/^#{target}.+#{ip}/).size
    
                if matches >= 1 
                    return true
                else
                    return false
                end
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
