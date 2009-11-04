module MCollective
    module Facts
        require 'facter'

        # A factsource for Reductive Labs Facter
        #
        # Plugin released under the terms of the GPL.
        class Facter<Base
            @@last_facts_load = 0

            def self.get_facts
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
