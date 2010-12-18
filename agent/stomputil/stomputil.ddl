metadata    :name        => "STOMP Connector Utility Agent",
            :description => "Various helpers and useful actions for the STOMP connector",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "Apache v 2.0",
            :version     => "1.0",
            :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
            :timeout     => 5

action "peer_info", :description => "Get STOMP Connection Peer" do
    display :always

    output :protocol,
           :description => "IP Protocol in use",
           :display_as => "Protocol"

    output :destport,
           :description => "Destination Port",
           :display_as => "Port"

    output :desthost,
           :description => "Destination Host",
           :display_as => "Host"

    output :destaddr,
           :description => "Destination Address",
           :display_as => "Address"
end

action "reconnect", :description => "Re-creates the connection to the STOMP network" do
    display :always

    output :restarted,
           :description => "Did the restart complete succesfully?",
           :display_as => "Restarted"
end
