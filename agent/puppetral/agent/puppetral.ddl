metadata    :name        => "Agent for Puppet RAL interaction",
            :description => "Agent to inspect and act on the RAL",
            :author      => "R.I.Pienaar, Max Martin",
            :license     => "ASL2",
            :version     => "0.2",
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

    input :title,
          :prompt      => "Resource name",
          :description => "Name of resource to add",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    input :avoid_conflict,
          :prompt      => "Avoid conflict",
          :description => "Resource property to ignore if there's a conflict",
          :type        => :string,
          :validation  => '.',
          :optional    => true,
          :maxlength   => 90

    output :output,
           :description => "Message indicating success or failure of the action",
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

    input :title,
          :prompt      => "Resource title",
          :description => "Name of resource to check",
          :type        => :string,
          :validation  => '.',
          :optional    => true,
          :maxlength   => 90

    output :type,
          :description => "Type of the inspected resource",
          :display_as  => "Type"

    output :title,
          :description => "Title of the inspected resource",
          :display_as  => "Title"

    output :tags,
          :description => "Tags of the inspected resource",
          :display_as  => "Tags"

    output :exported,
          :description => "Boolean flag indicating export status",
          :display_as  => "Exported"

    output :parameters,
          :description => "Parameters of the inspected resource",
          :display_as  => "Parameters"
end

action "search", :description => "Get the value of all resources of a certain type" do
    display :always

    input :type,
          :prompt      => "Resource type",
          :description => "Type of resource to check",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    output :result,
           :description => "Value of the inspected resources",
           :display_as  => "Result"
end
