metadata    :name        => "sysctl",
            :description => "Retrieve values for a given sysctl",
            :author      => "R.I.Pienaar <rip@devco.net>",
            :license     => "ASL 2.0",
            :version     => "1.0",
            :url         => "http://marionette-collective.org/",
            :timeout     => 1

dataquery :description => "Sysctl values" do
    input :query,
          :prompt => "Variable Name",
          :description => "Valid Variable Name",
          :type => :string,
          :validation => /^[\w\-\.]+$/,
          :maxlength => 120

    output :value,
           :description => "Kernel Parameter Value",
           :display_as => "Value"
end
