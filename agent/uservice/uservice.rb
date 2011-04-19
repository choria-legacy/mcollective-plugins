module MCollective
    module Agent
        # An agent to manage Ubuntu services
        #
        # Configuration Options:
        #    service.service - Location of service bin
        #
        class Uservice<RPC::Agent
            metadata    :name        => "SimpleRPC Ubuntu Service Agent",
                        :description => "Agent to manage Ubuntu services",
                        :author      => "Marc Cluet",
                        :license     => "Apache License 2.0",
                        :version     => "1.3",
                        :url         => "https://launchpad.net/~canonical-sig/",
                        :timeout     => 30

            def startup_hook
                @service = config.pluginconf["service.service"] || "/usr/sbin/service"
            end

            # Starts Service
            action "start" do
                if request[:service].nil?
                    fail "Service name not provided"
                end
                logger.debug ("Starting Service #{request[:service]}")
                reply[:exitcode] = run("#{@service} #{request[:service]} start", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error starting service #{request[:service]}."
                end
            end

            # Stops Service
            action "stop" do
                if request[:service].nil?
                    fail "Service name not provided"
                end
                logger.debug ("Stopping Service #{request[:service]}")
                reply[:exitcode] = run("#{@service} #{request[:service]} stop", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error stopping service #{request[:service]}."
                end
            end

            # Restarts Service
            action "restart" do
                if request[:service].nil?
                    fail "Service name not provided"
                end
                logger.debug ("Restarting Service #{request[:service]}")
                reply[:exitcode] = run("#{@service} #{request[:service]} restart", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error restarting service #{request[:service]}."
                end
            end

            # Gives back status
            action "status" do
                if request[:service].nil?
                    fail "Service name not provided"
                end
                logger.debug ("Getting Service status #{request[:service]}")
                reply[:exitcode] = run("#{@service} #{request[:service]} status", :stdout => :output, :stderr => :err, :chomp => true)
            end

        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
