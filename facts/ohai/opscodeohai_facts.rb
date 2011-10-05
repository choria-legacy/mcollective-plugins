require 'ohai'

module MCollective
  module Facts
    # A factsource for OpsCode Chef
    #
    # Generally using this plugin will slow down discovery by a couple of seconds
    #
    # See: http://projects.puppetlabs.com/projects/mcollective-plugins/wiki/FactsOhai
    #
    # NOTE: This version of this plugin requires mcollective 1.1.0 or newer
    #
    # Plugin released under the terms of the Apache Licence v 2.
    class Opscodeohai_facts<Base
      def load_facts_from_source
        Log.instance.debug("Reloading facts from Ohai")
        oh = Ohai::System.new
        oh.all_plugins

        facts = {}

        oh.data.each_pair do |key, val|
          ohai_flatten(key,val, [], facts)
        end

        facts
      end

      private
      # Flattens the Ohai structure into something like:
      #
      #  "languages.java.version"=>"1.6.0"
      def ohai_flatten(key, val, keys, result)
        keys << key
        if val.is_a?(Mash)
          val.each_pair do |nkey, nval|
            ohai_flatten(nkey, nval, keys, result)

            keys.delete_at(keys.size - 1)
          end
        else
          key = keys.join(".")
          if val.is_a?(Array)
            result[key] = val.join(", ")
          else
            result[key] = val
          end
        end
      end
    end
  end
end
# vi:tabstop=2:expandtab:ai
