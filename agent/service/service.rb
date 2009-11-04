module MCollective
    module Agent
        require 'puppet'

        # A agent that uses Reductive Labs puppet to manage services
        #
        # See http://code.google.com/p/mcollective-plugins/wiki/AgentPuppetService
        #
        # Released under the terms of the GPL, same as Puppet
        class Service
            attr_reader :timeout

            def initialize
                @timeout = 10
                @log = MCollective::Log.instance
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}

            end

            def handlemsg(msg, stomp)
                req = msg[:body]

                result = validate(req)

                unless result["status"]
                    service = req["service"]
                    action = req["action"]

                    @log.info("Doing #{action} for service #{service}")

                    begin
                        svc = Puppet::Type.type(:service).new(:name => service, :hasstatus => true).provider

                        if action != "status"
                            svc.send action
                            sleep 0.5
                        end

                        result["output"] = "success"
                        result["status"] = svc.status.to_s
                    rescue Exception => e
                        result["output"] = "Failed: #{e}"
                        result["status"] = "error"
                    end

                end

                result
            end

            def validate(req)
                result = {"output" => nil, "status" => nil}

                begin
                    raise "Request is not a hash" unless req.is_a?(Hash)
                    raise "Request has no 'service'" unless req["service"]
                    raise "Request has no 'action'" unless req["action"]
                rescue Exception => e
                    result = {"output" => e.to_s, "status" => "error"}
                end

                result
            end

            def help
                <<-EOH
                Service Agent
                =============

                Agent to manage services using the Puppet service provider

                Accepted Messages
                -----------------

                Input should be a hash of the form:

                {"service" => "httpd",
                 "action" => "stop"}

                Possible actions are: stop, start, restart, status

                Returned Data
                -------------

                In all cases a hash will be returned similar to:

                {:output    => "no output",
                 :svcstatus => :running}
                EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
