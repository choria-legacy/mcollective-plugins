metadata    :name        => "SimpleRPC Ubuntu Puppet Agent",
            :description => "Agent to manage puppet the Ubuntu way",
            :author      => "Marc Cluet",
            :license     => "Apache License 2.0",
            :version     => "1.3",
            :url         => "https://launchpad.net/~canonical-sig/",
            :timeout     => 1000

action "stop", :description => "Stops Puppet Service" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "start", :description => "Starts Puppet Service" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "restart", :description => "Restarts Puppet Service" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "cycle_run", :description => "Runs puppet service in cycle" do
    input  :numtimes, 
           :prompt      => "numtimes",
           :description => "Number of Times",
           :type        => :integer,
           :optional    => true,
           :maxlength   => 2

    output :result,
           :description => "Output fact",
           :display_as => "Output"
end


