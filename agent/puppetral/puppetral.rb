require 'puppet'

module MCollective
    module Agent
        # A SimpleRPC agent that uses the Puppet RAL to perform any action
        # that Puppet supports.
        #
        # To use this you can make requests like:
        #
        #   mc-rpc puppetral do type=user name=foo comment="Foo User"
        #
        # This will add a user foo with the correct comment:
        #
        #   mc-rpc puppetral do type=user name=foo comment="Foo User" ensure=absent
        #
        # This will remove the user.
        #
        # You can call any Puppet type that makes sense, you need to supply all the
        # needed properties that the type require etc.
        class Puppetral<RPC::Agent
            metadata    :name        => "puppetral",
                        :description => "Uses the Puppet RAL to perform actions on a server",
                        :author      => "R.I.Pienaar <rip@devco.net>",
                        :license     => "GPLv2",
                        :version     => "0.1",
                        :url         => "http://mcollective-plugins.googlecode.com/",
                        :timeout     => 180

            action "create" do
              inputs = request.data.clone

              type = inputs[:type]
              name = inputs[:name]

              res = Puppet::Resource.new(type, name, :parameters => inputs[:parameters]).save

              if res[:ensure] == :absent
                reply[:output] = "Resource was not created"
              else
                reply[:output] = "Resource was created"
              end
            end

            action "find" do
              type = request[:type]
              name = request[:name]

              result = Puppet::Resource.indirection.find([type, name].join('/')).to_pson_data_hash

              result.each { |k,v| reply[k] = v }
            end

            action "search" do
              type = request[:type]
              name = request[:name]

              result = Puppet::Resource.indirection.search(type, {}).map {|r| r.to_pson_data_hash}

              result.each {|r| reply[r["title"]] = r}
            end

            def resource_add(res)
            end
        end
    end
end
