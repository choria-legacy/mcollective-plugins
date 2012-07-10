module MCollective
  module Agent
    class Process<RPC::Agent
      metadata    :name        => "process",
                  :description => "Agent To Manage Processes",
                  :author      => "R.I.Pienaar",
                  :license     => "Apache 2.0",
                  :version     => "1.3",
                  :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
                  :timeout     => 10

      # List all processes, accepts an optional pattern
      action "list" do
        pattern = request[:pattern] || "."
        zombies = request[:just_zombies] || false

        reply[:pslist] = get_proc_list(pattern, zombies)
      end

      # Kills a certain pid with a signal
      action "kill" do
        validate :signal, :shellsafe
        validate :pid, /^\d+$/

        killpid(request[:signal], request[:pid].to_i)

        if reply.statuscode == 0
          reply[:killed] = 1
        else
          reply[:killed] = 0
        end
      end

      # Kills all processes matching a pattern
      # with a given signal
      action "pkill" do
        validate :signal, :shellsafe
        validate :pattern, String

        pids_to_kill = []

        get_proc_list(request[:pattern], false).each do |ps|
          pids_to_kill << ps[:pid]
        end

        # Sanity check
        if get_proc_list(".", false).size == pids_to_kill.size
          reply.fail "Pattern matches all (#{pids_to_kill.size}) processes, refusing to kill"
          return
        else
          reply[:killed] = 0

          pids_to_kill.each do |pid|
            system("logger -t mcolletive 'killing pid #{pid} based on pattern #{request[:pattern]}'")

            killpid(request[:signal], pid)

            # bail out if something went wrong
            last if reply.statuscode > 0

            reply[:killed] += 1
          end
        end
      end

      private
      # Sends a signal to a process
      def killpid(signal, pid)
        if signal =~ /^\d+$/
          signal = signal.to_i
        else
          signal = signal
        end

        if pid.is_a?(String)
          if pid =~ /^\d+/
            pid = pid.to_i
          else
            raise "pid should be a number"
          end
        end

        begin
          ::Process.kill(signal, pid)
        rescue Exception => e
          reply.fail e.to_s
        end
      end

      # Converts the weird structure of ProcTable into a plain old hash
      def ps_to_hash(ps)
        result = {}

        ps.each_pair do |k,v|
          if k == :uid
            begin
              result[:username] = Etc.getpwuid(v).name
            rescue Exception => e
              logger.debug("Could not get username for #{v}: #{e}")
              result[:username] = v
            end
          end

          result[k] = v
        end

        result
      end

      # Returns a hash of processes where cmdline matches pattern
      def get_proc_list(pattern, zombies)
        require 'sys/proctable'
        require 'etc'

        res = Sys::ProcTable.ps.map do |ps|
          ret = nil

          if ps["cmdline"] =~ /#{pattern}/
            if zombies
              ret = ps_to_hash(ps) if ps[:state] == "Z"
            else
              ret = ps_to_hash(ps)
            end
          end

          ret
        end

        res.compact
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai
