module MCollective
    module Agent
        # An agent that uses Reductive Labs Puppet to manage packages
        #
        # See http://code.google.com/p/mcollective-plugins/
        #
        # Released under the terms of the GPL, same as Puppet
        class Package<RPC::Agent
            attr_reader :timeout, :meta

            def startup_hook
                meta[:license] = "GPLv2"
                meta[:author] = "R.I.Pienaar"
                meta[:version] = "1.1"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 180
            end

            # All actions take a package, validating it here
            # avoid duplicating code
            def before_processing_hook(msg, connection)
                validate :package, :shellsafe
            end

            def install_action
                do_pkg_action(request[:package], :install)
            end

            def update_action
                do_pkg_action(request[:package], :update)
            end

            def uninstall_action
                do_pkg_action(request[:package], :uninstall)
            end

            def purge_action
                do_pkg_action(request[:package], :purge)
            end

            def status_action
                do_pkg_action(request[:package], :status)
            end

            private
            def do_pkg_action(package, action)
                begin
                    require 'puppet'

                    if Puppet.version =~ /0.24/
                        Puppet::Type.type(:package).clear
                        pkg = Puppet::Type.type(:package).create(:name => package).provider
                    else
                        pkg = Puppet::Type.type(:package).new(:name => package).provider
                    end

                    reply[:output] = ""
                    reply[:properties] = "unknown"

                    case action
                        when :install
                            reply[:output] = pkg.install if pkg.properties[:ensure] == :absent

                        when :update
                            reply[:output] = pkg.update if pkg.properties[:ensure] != :absent

                        when :uninstall
                            reply[:output] = pkg.uninstall

                        when :status
                            pkg.flush
                            reply[:output] = pkg.properties

                        when :purge
                            reply[:output] = pkg.purge

                        else
                            reply.fail "Unknown action #{action}"
                    end

                    pkg.flush
                    reply[:properties] = pkg.properties
                rescue Exception => e
                    reply.fail e.to_s
                end
            end

            def help
                <<-EOH
                Simple RPC Package agent using Puppet Providers
                ===============================================

                This is a package management agent that uses the Reductive Labs Puppet
                providers under the hood to achieve platform independance

                ACTION:
                    install, update, uninstall, purge, status

                INPUT:
                    :package    The package to affect

                OUTPUT:
                    :output     Output from Puppet - usually this is just nil
                    :properties The state of the package after the action was performed
                EOH
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
