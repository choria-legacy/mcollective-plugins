require 'augeas'

module MCollective
  module Agent
    # An agent to manage the Puppet Config
    #
    # Configuration Options:
    class Puppetconf<RPC::Agent
      metadata    :name        => "puppetconf",
                  :description => "Change puppet config for agent.",
                  :author      => "L.A.LindenLevy",
                  :license     => "Apache License 2.0",
                  :version     => "1.0",
                  :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/AgentPuppetConf",
                  :timeout     => 30

      action "environment" do
        environment
      end

      action "server" do
        server
      end

      def environment
        begin
          self.do_augeas("environment",request[:newval])
        rescue Augeas::Error
          reply.fail "Could not change environment"
        else
          reply[:output]="Succesfully changed environment"
        end
      end

      def server
        begin
          self.do_augeas("server",request[:newval])
        rescue Augeas::Error
          reply.fail "Could not change server"
        else
          reply[:output]="Succesfully changed server"
        end
      end

      def do_augeas(configname,value)
        configfile="/etc/puppet/puppet.conf"
        augeasconfig="/files/"+configfile+"/agent/"+configname
        Augeas::open(nil,nil,Augeas::NO_MODL_AUTOLOAD) do |aug|
          aug.transform(:lens => "Puppet.lns", :incl => configfile)
          aug.load!
          aug.set!(augeasconfig,value)
          aug.save!
        end
      end

    end # class
  end #Agent module
end #MCollective  module
