module MCollective
    module Agent
        # An agent to manage apt 
        #
        # Configuration Options:
        #    uapt.apt_get - Location of apt-get
        #
        class Uapt<RPC::Agent
            metadata    :name        => "SimpleRPC APT Ubuntu Agent",
                        :description => "Agent to manage apt the Ubuntu way",
                        :author      => "Marc Cluet",
                        :license     => "Apache License 2.0",
                        :version     => "1.3",
                        :url         => "https://launchpad.net/~canonical-sig/",
                        :timeout     => 360

            def startup_hook
                @apt_get = config.pluginconf["uapt.apt_get"] || "/usr/bin/apt-get"
            end

            # apt-get update
            action "update" do
                logger.debug ("Running apt-get update")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y update", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error updating apt repositories"
                end
            end

            # apt-get upgrade
            action "upgrade" do
                logger.debug ("Running apt-get upgrade")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y upgrade", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error upgrading packages"
                end
            end

            # apt-get dist-upgrade
            action "dist-upgrade" do
                logger.debug ("Running apt-get dist-upgrade")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y dist-upgrade", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running dist-upgrade"
                end
            end

            # apt-get install
            action "install" do
                logger.debug ("Running apt-get install #{request[:package]}")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y install #{request[:package]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running apt-get install #{request[:package]}"
                end
            end

            # apt-get -f install
            action "forceinstall" do
                logger.debug ("Running apt-get -f install")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -f install", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running apt-get -f install"
                end
            end

            # apt-get remove
            action "remove" do
                logger.debug ("Running apt-get remove #{request[:package]}")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y remove #{request[:package]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running apt-get remove #{request[:package]}"
                end
            end

            # apt-get source
            action "source" do
                logger.debug ("Running apt-get source #{request[:package]}")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} -y source #{request[:package]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running apt-get source #{request[:package]}"
                end
            end

            # apt-get clean
            action "clean" do
                logger.debug ("Running apt-get clean")
                reply[:exitcode] = run("export DEBIAN_FRONTEND=noninteractive; #{@apt_get} clean", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Error running apt-get clean"
                end
            end

        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
