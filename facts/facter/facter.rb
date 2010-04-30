module MCollective
    module Facts
        require 'facter'

        # A factsource for Reductive Labs Facter
        #
        # This plugin by default works with puppet facts loaded via pluginsync
        # and the deprecated factsync. If your facts are in a custom location, or
        # you use non-standard puppet dirs, then set plugin.facter.facterlib 
        # in the server.cfg
        #
        # It caches facts for 300 seconds to speed things up a bit,
        # generally though using this plugin will slow down discovery by
        # a second or so.
        #   - the cache time can be altered by setting plugin.facter.cache_time in the server.cfg
        #
        # See: http://code.google.com/p/mcollective-plugins/wiki/FactsRLFacter
        #
        # Plugin released under the terms of the GPL.
        class Facter<Base
            @@last_facts_load = 0

            def get_facts

                config = Config.instance
                logger = Log.instance

                ENV['FACTERLIB'] = config.pluginconf["facter.facterlib"] || "/var/lib/puppet/lib/facter:/var/lib/puppet/facts"
                cache_time = config.pluginconf["facter.cache_time"] || 300

                logger.debug("Have FACTERLIB: #{ENV['FACTERLIB']}")

                begin 
                    if (Time.now.to_i - @@last_facts_load > cache_time.to_i )
                        @@last_facts_load = Time.now.to_i
                        logger.debug("Resetting facter cache after #{cache_time} seconds")
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
