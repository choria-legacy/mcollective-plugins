metadata    :name        => "SimpleRPC Ubuntu Service Agent",
            :description => "Agent to manage services in Ubuntu",
            :author      => "Marc Cluet",
            :license     => "Apache License 2.0",
            :version     => "1.3",
            :url         => "https://launchpad.net/~canonical-sig/",
            :timeout     => 30

action "stop", :description => "Stops Service" do
    input  :service, 
           :prompt      => "service name",
           :description => "Service Name",
           :type        => :string,
           :optional    => false,
           :maxlength   => 50
end

action "start", :description => "Starts Service" do
    input  :service, 
           :prompt      => "service name",
           :description => "Service Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 50
end

action "restart", :description => "Restarts Service" do
    input  :service, 
           :prompt      => "service name",
           :description => "Service Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 50
end

action "status", :description => "Gets Service Status" do
    input  :service, 
           :prompt      => "service name",
           :description => "Service Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 50

    output :output,
           :description => "Output fact",
           :display_as => "Output"
end

