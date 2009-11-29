module MCollective
    module Facts
        require 'facter'

        # A factsource for Reductive Labs Facter
        #
        # This plugin currently assumes you put custom facts via
        # Puppets pluginsync in /var/lib/puppet/lib you can just edit
        # the path for now if your custom facts are elsewhere.
        #
        # It caches facts for 300 seconds to speed things up a bit,
        # generally though using this plugin will slow down discovery by
        # a second or so.
        #
        # See: http://code.google.com/p/mcollective-plugins/wiki/FactsRLFacter
        #
        # Plugin released under the terms of the GPL.
        class Facter<Base
            @@last_facts_load = 0

            def get_facts
                unless $LOAD_PATH.include?("/var/lib/puppet/lib")
                    $LOAD_PATH << "/var/lib/puppet/lib"
                end
    
                begin 
                    if (Time.now.to_i - @@last_facts_load > 300)
                        @@last_facts_load = Time.now.to_i
                        ::Facter.reset
                    end
                rescue
                    @@last_facts_load = Time.now.to_i
                end
    
                ::Facter.to_hash
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
