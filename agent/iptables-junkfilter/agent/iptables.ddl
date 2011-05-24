metadata    :name        => "SimpleRPC IP Tables Agent",
            :description => "An agent that manipulates a chain called 'junkfilter' with iptables",
            :author      => "R.I.Pienaar",
            :license     => "Apache 2",
            :version     => "1.3",
            :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
            :timeout     => 2

["block", "unblock"].each do |act|
    action act, :description => "#{act.capitalize} an IP" do
        input :ipaddr,
              :prompt      => "IP address",
              :description => "The IP address to #{act}",
              :type        => :string,
              :validation  => '^\d+\.\d+\.\d+\.\d+$',
              :optional    => false,
              :maxlength   => 15

        output :output,
               :description => "Output from iptables or a human readable status",
               :display_as  => "Result"
    end
end

action "listblocked", :description => "Returns list of blocked ips" do
    display :always

    output :blocked,
           :description => "Blocked IPs",
           :display_as => "Blocked"
end

action "isblocked", :description => "Check if an IP is blocked" do
    display :always

    input :ipaddr,
          :prompt      => "IP address",
          :description => "The IP address to check",
          :type        => :string,
          :validation  => '^\d+\.\d+\.\d+\.\d+$',
          :optional    => false,
          :maxlength   => 15

    output :output,
           :description => "Human readable indication if the IP is blocked or not",
           :display_as  => "Result"
end
