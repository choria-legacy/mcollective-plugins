metadata :name        => "puppetconf",
         :description => "Change config for puppet agent.",
         :author      => "L.A.LindenLevy",
         :license     => "Apache License 2.0",
         :version     => "1.0",
         :url         => "https://github.com/puppetlabs/mcollective-plugins",
         :timeout     => 30

action "environment", :description => "Change the puppet environment on an agent" do
       display  :always

       input :newval,
             :prompt => "New environment",
             :description => "The environment you want to change to",
             :type => :string,
             :validation  => '^[a-zA-Z_\d]+$',
             :maxlength => 70,
             :optional => false

       output :output,
              :description =>"String indicating status",
              :display_as => "Status"
 
end

action "server", :description => "Change the puppetmaster server on an agent" do
       display :always

       input :newval,
             :prompt => "New server",
             :description => "The server you want to change to",
             :type => :string,
             :validation  => '^[a-zA-Z\-_\d\.]+$',
             :maxlength => 70,
             :optional => false

       output :output,
              :description =>"String indicating status",
              :display_as => "Status"
end

