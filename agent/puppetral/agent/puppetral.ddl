metadata    :name        => "puppetral",
            :description => "View and edit resources with Puppet's resource abstraction layer",
            :author      => "R.I.Pienaar, Max Martin",
            :license     => "ASL2",
            :version     => "0.4",
            :url         => "https://github.com/puppetlabs/mcollective-plugins",
            :timeout     => 180

action "create", :description => "Add a resource via the RAL" do
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

    output :status,
           :description => "Message indicating success or failure of the action",
           :display_as  => "Status"

    output :resource,
           :description => "Resource that was created",
           :display_as  => "Resource"

end

action "find", :description => "Get the attributes and status of a resource" do
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
          :optional    => false,
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

action "search", :description => "Get detailed info for all resources of a given type" do
    display :always

    input :type,
          :prompt      => "Resource type",
          :description => "Type of resource to check",
          :type        => :string,
          :validation  => '.',
          :optional    => false,
          :maxlength   => 90

    output :result,
           :description => "The values of the inspected resources",
           :display_as  => "Result"
end
