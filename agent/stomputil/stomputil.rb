module MCollective
    module Agent
        class Stomputil<RPC::Agent
            metadata    :name        => "STOMP Connector Utility Agent",
                        :description => "Various helpers and useful actions for the STOMP connector",
                        :author      => "R.I.Pienaar <rip@devco.net>",
                        :license     => "Apache v 2.0",
                        :version     => "1.0",
                        :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
                        :timeout     => 5

            # Get the Stomp connection peer information
            action "peer_info" do
                peer = PluginManager["connector_plugin"].connection.socket.peeraddr

                reply[:protocol] = peer[0]
                reply[:destport] = peer[1]
                reply[:desthost] = peer[2]
                reply[:destaddr] = peer[3]
            end

            action "reconnect" do
                PluginManager["connector_plugin"].disconnect

                sleep 0.5

                PluginManager["connector_plugin"].connect

                ::Process.kill("USR1", $$)

                reply[:restarted] = 1
            end

            private
            def get_pid(process)
                pid = `pidof #{process}`.chomp.grep(/\d+/)

                pid.first
            end
        end
    end
end
