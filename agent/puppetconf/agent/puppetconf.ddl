metadata    :name        => "puppetconf",
            :description => "Change config for puppet agent.",
            :author      => "L.A.LindenLevy",
            :license     => "Apache License 2.0",
            :version     => "1.0",
            :url         => "https://github.com/puppetlabs/mcollective-plugins",
            :timeout     => 20

action "environment", :description => "Change the puppet environment on an agent" do
end

action "server", :description => "Change the puppetmaster server on an agent" do
end

