metadata    :name        => "SimpleRPC Ubuntu Kill Agent",
            :description => "Agent to kill instances",
            :author      => "Marc Cluet",
            :license     => "Apache License 2.0",
            :version     => "1.3",
            :url         => "https://launchpad.net/~canonical-sig/",
            :timeout     => 30

action "kill", :description => "Kills instance nicely" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "forcekill", :description => "Kills instance the nasty way" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

