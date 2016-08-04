module MCollective
    module Agent
        # An agent to manage Facts
        #
        # Configuration Options:
        #    fact.fact_add - Add a new fact
        #    fact.fact_del - Deletes an existing fact
        #
        class Fact<RPC::Agent
            metadata    :name        => "SimpleRPC Fact Agent",
                        :description => "Agent to manage Facts",
                        :author      => "Marc Cluet",
                        :license     => "Apache License 2.0",
                        :version     => "1.3",
                        :url         => "https://launchpad.net/~canonical-sig/",
                        :timeout     => 20

            def startup_hook
                @fact_add = config.pluginconf["fact.fact_add"] || "/usr/bin/fact-add"
                @fact_del = config.pluginconf["fact.fact_del"] || "/usr/bin/fact-del"
                @facter = config.pluginconf["fact.facter"] || "/usr/bin/facter"
            end

            # Adds a new fact
            action "add" do
                logger.debug ("Request for adding fact #{request[:fact]} with value #{request[:value]}")
                reply[:exitcode] = run("#{@fact_add} #{request[:fact]} #{request[:value]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Unable to add fact"
                end
            end

            # Deletes an existing fact
            action "del" do
                logger.debug ("Request for deleting fact #{request[:fact]}")
                reply[:exitcode] = run("#{@fact_add} #{request[:fact]} #{request[:value]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    fail "Can't delete not existing fact"
                end
            end

            # Reads a fact
            action "read" do
                logger.debug ("Request for reading fact #{request[:fact]}")
                reply[:output] = PluginManager["facts_plugin"].get_fact("#{request[:fact]}")
                reply[:exitcode] = 0
            end

        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
