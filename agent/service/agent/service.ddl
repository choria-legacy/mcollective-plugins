metadata    :name        => "Service Agent",
            :description => "Start and stop system services",
            :author      => "R.I.Pienaar",
            :license     => "ASL2",
            :version     => "1.2",
            :url         => "https://github.com/puppetlabs/mcollective-plugins",
            :timeout     => 60

action "status", :description => "Gets the status of a service" do
    display :always

    input :service,
          :prompt      => "Service Name",
          :description => "The service to get the status for",
          :type        => :string,
          :validation  => '^[a-zA-Z\.\-_\d]+$',
          :optional    => false,
          :maxlength   => 90

    output "status",
          :description => "The status of the service",
          :display_as  => "Service Status"
end

["stop", "start", "restart"].each do |act|
    action act, :description => "#{act.capitalize} a service" do
        display :failed

        input :service,
              :prompt      => "Service Name",
              :description => "The service to #{act}",
              :type        => :string,
              :validation  => '^[a-zA-Z\.\-_\d]+$',
              :optional    => false,
              :maxlength   => 90

        output "status",
              :description => "The status of the service after #{act.sub(/p$/, 'pp')}ing",
              :display_as  => "Service Status"
    end
end
