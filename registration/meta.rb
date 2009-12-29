module MCollective
    module Registration
        # A registration plugin that sends in all the meta data we have for a node:
        #
        # - all facts
        # - all agents
        # 
        # will add cf classes soon
        #
        # http://code.google.com/p/mcollective-plugins/wiki/RegistrationMetaData
        # Author: R.I.Pienaar <rip@devco.net>
        # Licence: Apache 2
        class Meta<Base
            def body
                {:agentlist => Agents.agentlist,
                 :facts => PluginManager["facts_plugin"].get_facts}
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
