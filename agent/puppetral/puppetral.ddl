metadata    :name        => "Agent for Puppet RAL interaction",
            :description => "Agent to inspect and act on the RAL",
            :author      => "R.I.Pienaar, Max Martin",
            :license     => "GPLv2",
            :version     => "1.3",
            :url         => "http://mcollective-plugins.googlecode.com/",
            :timeout     => 180

action "create", :description => "Add a resource to the RAL" do
    display :always

    input :type,
          :prompt      => "Resource type",
          :description => "Type of resource to add",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    input :name,
          :prompt      => "Resource name",
          :description => "Name of resource to add",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    output :result,
           :description => "Result of the action",
           :display_as  => "Result"
end

action "create_from_pson", :description => "Add a resource to the RAL from PSON" do
    display :always

    input :pson,
          :prompt      => "Resource PSON hash",
          :description => "PSON data hash representing a Puppet resource",
          :type        => :hash,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    output :result,
           :description => "Result of the action",
           :display_as  => "Result"
end

action "find", :description => "Get the value of a resource" do
    display :always

    input :type,
          :prompt      => "Resource type",
          :description => "Type of resource to check",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    input :name,
          :prompt      => "Resource name",
          :description => "Name of resource to check",
          :type        => :string,
          :validation  => '.',
          :optional    => true,
          :maxlength   => 90

    output :result,
           :description => "Value of the inspected resource",
           :display_as  => "Result"
end
