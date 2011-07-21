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

            action "do" do
                require 'puppet'

                params = request.data.clone

                type = request[:type]

                params.delete :type
                params.delete :process_results

                pup = Puppet::Type.type(type).new(params)

                catalog = Puppet::Resource::Catalog.new
                catalog.add_resource pup

                catalog.apply

                reply[:result] = "OK"
            end

            action "find" do
              require 'puppet'

              type = request[:type]
              name = request[:name]

              if name
                reply[:result] = Puppet::Resource.find([type, name].join('/')).to_pson_data_hash
              else
                reply[:result] = Puppet::Resource.search(type, {}).to_pson_data_hash
              end
            end
        end
    end
end
