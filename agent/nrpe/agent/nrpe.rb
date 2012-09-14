module MCollective
  module Agent
    class Nrpe<RPC::Agent
      metadata    :name        => "nrpe",
                  :description => "Agent to query NRPE commands via MCollective",
                  :author      => "R.I.Pienaar",
                  :license     => "Apache 2",
                  :version     => "2.2",
                  :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
                  :timeout     => 5

      action "runcommand" do
        validate :command, :shellsafe

        command = plugin_for_command(request[:command])

        reply[:command] = request[:command]
        reply[:output] = ""
        reply[:perfdata] = ""

        if command == nil
          reply[:output] = "No such command: #{request[:command]}" if command == nil
          reply[:exitcode] = 3

          reply.fail! "UNKNOWN"
        end

        reply[:exitcode] = run(command[:cmd], :stdout => :output, :chomp => true)

        case reply[:exitcode]
          when 0
            reply.statusmsg = "OK"

          when 1
            reply.fail! "WARNING"

          when 2
            reply.fail! "CRITICAL"

          else
            reply.fail! "UNKNOWN"

        end

        if reply[:output] =~ /^(.+)\|(.+)$/
          reply[:output] = $1
          reply[:perfdata] = $2
        end
      end

      private
      def plugin_for_command(req)
        ret = nil
        fname = nil

        fdir  = config.pluginconf["nrpe.conf_dir"] || "/etc/nagios/nrpe.d"

        if config.pluginconf["nrpe.conf_file"]
          fname = "#{fdir}/#{config.pluginconf['nrpe.conf_file']}"
        else
          fname = "#{fdir}/#{req}.cfg"
        end

        if File.exist?(fname)
          t = File.readlines(fname)
          t.each do |check|
            check.chomp!

            if check =~ /command\[#{request[:command]}\]=(.+)$/
              ret = {:cmd => $1}
            end
          end
        end

        ret
      end
    end
  end
end
# vi:tabstop=2:expandtab:ai
