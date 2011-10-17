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
               :url         => "https://github.com/puppetlabs/mcollective-plugins",
               :timeout     => 180

      action "create" do
        type = request[:type]
        title = request[:title]
        parameters = request[:parameters]

        parameters = remove_conflicts(type, title, parameters, request[:avoid_conflict])

        resource = Puppet::Resource.new(type, title, :parameters => parameters)
        result, report = Puppet::Resource.indirection.save(resource)

        success = true
        if report && report.resource_statuses.first.last.failed
          reply[:output] = report.resource_statuses.first.last.events.first.message
          success = false
        end

        reply[:output] = "Resource was created" if success
      end

      # Remove the avoid_conflict property if it clashes in one or more of
      # the following ways:
      #   1) A resource of the same type exists and has the same value for
      #      the avoid_conflict property.
      #   2) A resource of the same type and title exists.
      def remove_conflicts(type, title, parameters, key)
        if key && parameters.has_key?(key)
          value = parameters[key]
          search_result = Puppet::Resource.indirection.search(type, {})
          search_result.each do |result|
            resource = result.to_pson_data_hash
            if resource['parameters'][key.to_sym].to_s == value.to_s || resource['title'] == title
              parameters.delete key
              return parameters
            end
          end
        end
        parameters
      end

      # Before returning resources we will prune the parameters
      # so only properties remain, but certain types should have some of their
      # parameters retained (mostly, packages need provider info)
      def retain_params(resource)
        provider = resource[:provider] if resource.type.downcase == 'package'
        result = resource.respond_to?(:prune_parameters) ?
          resource.prune_parameters.to_pson_data_hash : resource.to_pson_data_hash
        result['parameters'][:provider] = provider if provider
        result
      end

      action "find" do
        type = request[:type]
        title = request[:title]
        typeobj = Puppet::Type.type(type) or raise "Could not find type #{type}"

        if typeobj
          resource = Puppet::Resource.indirection.find([type, title].join('/'))
          retain_params(resource).each { |k,v| reply[k] = v }

          begin
            managed_resources = File.readlines(Puppet[:resourcefile])
            managed_resources = managed_resources.map{|r|r.chomp}
            reply[:managed] = managed_resources.include?("#{type}[#{title}]")
          rescue
            reply[:managed] = "unknown"
          end
        end
      end

      action "search" do
        type = request[:type]
        typeobj = Puppet::Type.type(type) or raise "Could not find type #{type}"

        if typeobj
          result = Puppet::Resource.indirection.search(type, {}).map do |r|
            retain_params(r)
          end

          result.each {|r| reply[r["title"]] = r}
        end
      end
    end
  end
end
