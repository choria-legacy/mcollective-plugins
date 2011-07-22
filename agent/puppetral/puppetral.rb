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
                params = request.data.clone

                type = request[:type]

                params.delete :type
                params.delete :process_results

                pup = Puppet::Type.type(type).new(params)
                resource_add(pup)

                reply[:result] = "OK"
            end

            action "create_from_pson" do
              data = request[:pson]

              res = Puppet::Resource.from_pson(data).to_ral
              resource_add(res)

              reply[:result] = "OK"
            end

            action "find" do
              type = request[:type]
              name = request[:name]

              reply[:result] = if name
                resource_find([type, name].join('/'))
              else
                resource_search(type)
              end
            end

            def resource_find(title)
              Puppet::Resource.find(title).to_pson_data_hash
            end

            def resource_search(type)
              Puppet::Resource.search(type, {}).to_pson_data_hash
            end

            def resource_add(res)
              catalog = Puppet::Resource::Catalog.new
              catalog.add_resource(res)

              catalog.apply
            end
        end
    end
end
