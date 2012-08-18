metadata    :name        => "nrpe",
            :description => "Agent to query NRPE commands via MCollective",
            :author      => "R.I.Pienaar",
            :license     => "Apache 2",
            :version     => "2.2",
            :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
            :timeout     => 5


action "runcommand", :description => "Run a NRPE command" do
    input :command,
          :prompt      => "Command",
          :description => "NRPE command to run",
          :type        => :string,
          :validation  => '\A[a-zA-Z0-9_-]+\z',
          :optional    => false,
          :maxlength   => 50

    output :output,
           :description => "Output from the Nagios plugin",
           :display_as  => "Output",
           :default     => ""

    output :exitcode,
           :description  => "Exit Code from the Nagios plugin",
           :display_as   => "Exit Code",
           :default      => 3

    output :perfdata,
           :description  => "Performance Data from the Nagios plugin",
           :display_as   => "Performance Data",
           :default      => ""

    output :command,
           :description  => "Command that was run",
           :display_as   => "Command",
           :default      => ""

    if respond_to?(:summarize)
        summarize do
            aggregate nagios_states(:exitcode)
        end
    end
end

