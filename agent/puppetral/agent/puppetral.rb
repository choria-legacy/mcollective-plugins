require 'puppet'

module MCollective
  module Agent
    # A SimpleRPC agent that uses the Puppet RAL to perform any action
    # that Puppet supports.
    #
    # To use this you can make requests like:
    #
    #   mc-rpc puppetral create type=user name=foo comment="Foo User"
    #
    # This will add a user foo with the correct comment:
    #
    #   mc-rpc puppetral create type=user name=foo comment="Foo User" ensure=absent
    #
    # This will remove the user.
    #
    # You can call any Puppet type that makes sense, you need to supply all the
    # needed properties that the type require etc.
    class Puppetral<RPC::Agent
      metadata :name        => "puppetral",
               :description => "Agent to inspect and act on the RAL",
               :author      => "R.I.Pienaar <rip@devco.net>, Max Martin <max@puppetlabs.com>",
               :license     => "ASL2",
               :version     => "0.2",
               :url         => "http://mcollective-plugins.googlecode.com/",
               :timeout     => 180

      action "create" do
        inputs = request.data.clone

        res = Puppet::Resource.new(inputs[:type], inputs[:title], :parameters => inputs[:parameters]).save

        if res[:ensure] == :absent
          reply[:output] = "Resource was not created"
        else
          reply[:output] = "Resource was created"
        end
      end

      action "find" do
        type = request[:type]
        name = request[:name]
        typeobj = Puppet::Type.type(type) or raise "Could not find type #{type}"

        if typeobj
          result = Puppet::Resource.indirection.find([type, name].join('/')).to_pson_data_hash

          result.each { |k,v| reply[k] = v }
        end
      end

      action "search" do
        type = request[:type]
        name = request[:name]
        typeobj = Puppet::Type.type(type) or raise "Could not find type #{type}"

        if typeobj
          result = Puppet::Resource.indirection.search(type, {}).map {|r| r.to_pson_data_hash}

          result.each {|r| reply[r["title"]] = r}
        end
      end
    end
  end
end
