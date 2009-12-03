module MCollective
    module Agent
        # An agent that calls nagios plugins on remote hosts by parsing nrpe configs
        #
        # Not to be released in public
        class Nrpe
            attr_reader :timeout, :meta
            def initialize
                @timeout = 1
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}
            end

            def handlemsg(msg, connection)
                req = msg[:body]

                output = {:string => "unknown", :status => "UNKNOWN", :exit => 3, :perfdata => ""}

                begin
                    input = validate(req)

                    raise("Unknown plugin #{req}") if input == nil

                    output[:string] = %x[#{input[:cmd]}]

                    if output[:string] =~ /^(.+)\|(.+)$/
                        output[:string] = $1
                        output[:perfdata] = $2
                    end

                    output[:exit] = $?.exitstatus

                    case output[:exit]
                        when 0
                            output[:status] = "OK"
                        when 1
                            output[:status] = "WARNING"
                        when 2
                            output[:status] = "CRITICAL"
                        else
                            output[:status] = "UNKNOWN"

                    end
                rescue Exception => e
                    output[:string] = e.to_s
                    output[:exit] = 3
                end

                output
            end

            def validate(req)
                ret = nil

                fname = "/etc/nagios/nrpe.d/#{req}.cfg"

                if File.exist?(fname)
                    t = File.readlines(fname).first.chomp

                    if t =~ /command\[.+\]=(.+)$/
                        ret = {:cmd => $1}
                    end
                end

                ret
            end

            def help
            <<-EOH
            NRPE Agent
            ==========

            Agent that looks for defined commands in /etc/nagios/nrpe.d and runs the command.

            Returns a hash of :string, :exit, :status and :perfdata
            EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
