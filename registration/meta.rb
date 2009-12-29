module MCollective
    module Registration
        # A registration plugin that sends in all the meta data we have for a node:
        #
        # - all facts
        # - all agents
        # 
        # will add cf classes soon
        class Meta<Base
            def body
                {:agentlist => Agents.agentlist,
                 :facts => PluginManager["facts_plugin"].get_facts}
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
