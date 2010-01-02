module MCollective
    module Agent
        # An agent that uses Reductive Labs puppet to manage services
        #
        # See http://code.google.com/p/mcollective-plugins/
        #
        # Released under the terms of the GPL, same as Puppet
        #
        # Agent is based on Simple RPC so needs mcollective 0.4.0 or newer
        class Service<RPC::Agent
            def startup_hook
                meta[:license] = "GPLv2"
                meta[:author] = "R.I.Pienaar"
                meta[:version] = "1.1"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 60
            end

            def restart_action
                do_service_action("restart")
            end

            def stop_action
                do_service_action("stop")
            end

            def start_action
                do_service_action("start")
            end

            def status_action
                do_service_action("status")
            end

            private
            # Creates an instance of the Puppet service provider, supports config options:
            #
            # - service.hasrestart - set this if your OS provides restart options on services
            # - service.hasstatus  - set this if your OS provides status options on services
            def get_puppet(service)
                hasstatus = false
                hasrestart = false

                if @config.pluginconf.include?("service.hasrestart")
                    hasrestart = true if @config.pluginconf["service.hasrestart"] =~ /^1|y|t/
                end
                    
                if @config.pluginconf.include?("service.hasstatus")
                    hasstatus = true if @config.pluginconf["service.hasstatus"] =~ /^1|y|t/
                end
                    
                require 'puppet'

                if Puppet.version =~ /0.24/
                    Puppet::Type.type(:service).clear
                    svc = Puppet::Type.type(:service).create(:name => service, :hasstatus => hasstatus, :hasrestart => hasrestart).provider
                else
                    svc = Puppet::Type.type(:service).new(:name => service, :hasstatus => hasstatus, :hasrestart => hasrestart).provider
                end

                svc
            end

            # Does the actual work with the puppet provider and sets appropriate reply options
            def do_service_action(action)
                validate :service, String

                service = request[:service]

                begin
                    Log.instance.debug("Doing #{action} for service #{service}")

                    svc = get_puppet(service)

                    unless action == "status"
                        svc.send action
                        sleep 0.5
                    end

                    reply["status"] = svc.status.to_s
                rescue Exception => e
                    reply.fail "#{e}"
                end
            end

            def help
                <<-EOH
                Simple RPC Service Agent
                ========================

                Agent to manage services using the Puppet service provider

                ACTIONS:
                    start, stop, restart and status

                INPUT:
                    :service    the name of the service to manage

                OUTPUT:
                    :status     the status from puppet
                EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
