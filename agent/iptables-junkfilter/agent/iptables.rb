require 'socket'

module MCollective
  module Agent
    # An agent that manipulates a chain called 'junkfilter' with iptables
    #
    # See http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentIptablesJunkfilter
    #
    # Released under the terms of the GPL
    class Iptables<RPC::Agent
      metadata    :name        => "SimpleRPC IP Tables Agent",
                  :description => "An agent that manipulates a chain called 'junkfilter' with iptables",
                  :author      => "R.I.Pienaar",
                  :license     => "Apache 2",
                  :version     => "2.0",
                  :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
                  :timeout     => 2

      action "block" do
        validate :ipaddr, :ipv4address

        blockip(request[:ipaddr])
      end

      action "unblock" do
        validate :ipaddr, :ipv4address

        unblockip(request[:ipaddr])
      end

      action "isblocked" do
        validate :ipaddr, :ipv4address

        isblocked(request[:ipaddr])
      end

      action "listblocked" do
        reply[:blocked] = listblocked
      end

      private
      # Deals with requests to block an ip
      def blockip(ip)
        logger.debug("Blocking #{ip} with target #{target}")

        out = ""

        # if he's already blocked we just dont bother doing it again
        unless isblocked?(ip)
          run("/sbin/iptables -A junk_filter -s #{ip} -j #{target} 2>&1", :stdout => out, :chomp => true)
          run("/usr/bin/logger -i -t mcollective 'Attempted to add #{ip} to iptables junk_filter chain on #{Socket.gethostname}'")
        else
          reply.fail! "#{ip} was already blocked"
          return
        end

        if isblocked?(ip)
          unless out == ""
            reply[:output] = out
          else
            reply[:output] = "#{ip} was blocked"
          end
        else
          reply.fail! "Failed to add #{ip}: #{out}"
        end
      end

      # Deals with requests to unblock an ip
      def unblockip(ip)
        logger.debug("Unblocking #{ip} with target #{target}")

        out = ""

        # remove it if it's blocked
        if isblocked?(ip)
          run("/sbin/iptables -D junk_filter -s #{ip} -j #{target} 2>&1", :stdout => out, :chomp => true)
          run("/usr/bin/logger -i -t mcollective 'Attempted to remove #{ip} from iptables junk_filter chain on #{Socket.gethostname}'")
        else
          reply.fail! "#{ip} was already unblocked"
          return
        end

        # check it was removed
        if isblocked?(ip)
          reply.fail! "IP left blocked, iptables says: #{out}"
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

        prematches = ""
        run("/sbin/iptables -L junk_filter -n 2>&1", :stdout => prematches, :chomp => true)

        matches = prematches.split("\n").grep(/^#{target}.+#{ip}/).size
        matches >= 1
      end

      # Returns a list of blocked ips
      def listblocked
        preout = ""
        run("/sbin/iptables -L junk_filter -n 2>&1", :stdout => preout, :chomp => true)

        out = preout.split("\n").grep(/^#{target}/)
        out.map {|l| l.split(/\s+/)[3]}
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

# vi:tabstop=2:expandtab:ai:filetype=ruby
