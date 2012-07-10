metadata    :name        => "resource",
            :description => "Information about Puppet managed resources",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "http://marionette-collective.org/",
            :timeout     => 1

dataquery :description => "Puppet Managed Resources" do
    input :query,
          :prompt => "Resource Name",
          :description => "Valid resource name",
          :type => :string,
          :validation => /^.+$/,
          :optional => true,
          :maxlength => 120

    output :managed,
           :description => "Is the resource managed",
           :display_as => "Managed"

    output :count,
           :description => "Total managed resources",
           :display_as => "Count"

    output :age,
           :description => "Resources list age",
           :display_as => "Age"
end
