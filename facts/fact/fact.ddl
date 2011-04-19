metadata    :name        => "SimpleRPC Fact Agent",
            :description => "Agent to manage facts",
            :author      => "Marc Cluet",
            :license     => "Apache License 2.0",
            :version     => "1.3",
            :url         => "https://launchpad.net/~canonical-sig/",
            :timeout     => 20

action "add", :description => "Adds fact" do
    input  :fact, 
           :prompt      => "fact",
           :description => "Fact Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90

    input  :value, 
           :prompt      => "value",
           :description => "Value",
           :type        => :string,
           :optional    => false,
           :maxlength   => 90
end

action "del", :description => "Deletes fact" do
    input  :fact, 
           :prompt      => "fact",
           :description => "Fact Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90
end

action "read", :description => "Reads fact" do
    input  :fact, 
           :prompt      => "fact",
           :description => "Fact Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90

    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

