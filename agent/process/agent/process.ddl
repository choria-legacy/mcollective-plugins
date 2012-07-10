metadata    :name        => "process",
            :description => "Agent To Manage Processes",
            :author      => "R.I.Pienaar",
            :license     => "Apache 2.0",
            :version     => "1.3",
            :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
            :timeout     => 10

action "list", :description => "List Processes" do
    input :pattern,
          :prompt      => "Pattern to match",
          :description => "List only processes matching this patten",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => true,
          :maxlength    => 50

    input :just_zombies,
          :prompt      => "Zombies Only",
          :description => "Restrict the process list to Zombie Processes only",
          :type        => :boolean,
          :optional    => true

    output :pslist,
           :description => "Process List",
           :display_as => "The process list"
end

action "kill", :description => "Kills a process" do
    input :pid,
          :prompt      => "PID",
          :description => "The PID to kill",
          :type        => :string,
          :validation  => '^\d+$',
          :optional    => false,
          :maxlength    => 6

    input :signal,
          :prompt      => "Signal",
          :description => "The signal to send",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength    => 6

    output :killed,
           :description => "Indicates if the process was signalled",
           :display_as => "Status"
end

action "pkill", :description => "Kill all processes matching filter" do
    input :pattern,
          :prompt      => "Pattern to match",
          :description => "List only processes matching this patten",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => true,
          :maxlength    => 50

    input :signal,
          :prompt      => "Signal",
          :description => "The signal to send",
          :type        => :string,
          :validation  => '^.+$',
          :optional    => false,
          :maxlength    => 6

    output :killed,
           :description => "Number of processes signalled",
           :display_as => "Processes Signalled"
end
