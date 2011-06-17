metadata    :name        => "SimpleRPC Agent For Package Management",
            :description => "Agent To Manage Packages",
            :author      => "R.I.Pienaar",
            :license     => "GPLv2",
            :version     => "1.3",
            :url         => "http://mcollective-plugins.googlecode.com/",
            :timeout     => 180

["install", "update", "uninstall", "purge"].each do |act|
    action act, :description => "#{act.capitalize} a package" do
        input :package,
              :prompt      => "Package Name",
              :description => "Package to #{act.capitalize}",
              :type        => :string,
              :validation  => '.',
              :optional    => false,
              :maxlength   => 90

        output :output,
               :description => "Output from the package manager",
               :display_as  => "Output"

        output :properties,
               :description => "Properties about the package post #{act}",
               :display_as  => "Properties"
    end
end

action "status", :description => "Get the status of a package" do
    display :always

    input :package,
          :prompt      => "Package Name",
          :description => "Package to retrieve the status of",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    output :output,
           :description => "Output from the package manager",
           :display_as  => "Output"

    output :properties,
           :description => "Package Properties",
           :display_as  => "Properties"
end

action "yum_clean", :description => "Clean the YUM cache" do
    output :output,
           :description => "Output from YUM",
           :display_as  => "Output"

    output :exitcode,
           :description => "The exitcode from the yum command",
           :display_as => "Exit Code"
end

action "apt_update", :description => "Updated the apt cache" do
    output :output,
           :description => "Output from apt-get",
           :display_as  => "Output"

    output :exitcode,
           :description => "The exitcode from the apt-get command",
           :display_as => "Exit Code"
end

action "yum_checkupdates", :description => "Check for YUM updates" do
    display :always

    output :output,
           :description => "Output from YUM",
           :display_as  => "Output"

    output :oudated_packages,
           :description => "Outdated packages",
           :display_as  => "Outdated Packages"

    output :exitcode,
           :description => "The exitcode from the yum command",
           :display_as => "Exit Code"
end

action "apt_checkupdates", :description => "Check for APT updates" do
    display :always

    output :output,
           :description => "Output from APT",
           :display_as  => "Output"

    output :oudated_packages,
           :description => "Outdated packages",
           :display_as  => "Outdated Packages"

    output :exitcode,
           :description => "The exitcode from the apt command",
           :display_as => "Exit Code"
end

action "checkupdates", :description => "Check for updates" do
    display :always

    output :package_manager,
           :description => "The detected Package Manager",
           :display_as  => "Package Manager"

    output :output,
           :description => "Output from Package Manager",
           :display_as  => "Output"

    output :outdated_packages,
           :description => "Outdated packages",
           :display_as  => "Outdated Packages"

    output :exitcode,
           :description => "The exitcode from the package manager command",
           :display_as => "Exit Code"
end
