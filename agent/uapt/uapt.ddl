metadata    :name        => "SimpleRPC Ubuntu APT Agent",
            :description => "Agent to manage apt the Ubuntu way",
            :author      => "Marc Cluet",
            :license     => "Apache License 2.0",
            :version     => "1.3",
            :url         => "https://launchpad.net/~canonical-sig/",
            :timeout     => 360

action "update", :description => "Update APT" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "upgrade", :description => "Upgrade APT" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "dist-upgrade", :description => "Dist-Upgrade APT" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "install", :description => "Installs package through APT" do
    input  :package, 
           :prompt      => "package name",
           :description => "Package Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90

    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "forceinstall", :description => "Force installs package through APT" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "remove", :description => "Removes package through APT" do
    input  :package, 
           :prompt      => "package name",
           :description => "Package Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90

    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "source", :description => "Installs source package through APT" do
    input  :package, 
           :prompt      => "package name",
           :description => "Package Name",
           :type        => :string,
           :validation  => '.',
           :optional    => false,
           :maxlength   => 90

    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

action "clean", :description => "Clean downloaded packages through APT" do
    output :result,
           :description => "Output fact",
           :display_as => "Output"
end

