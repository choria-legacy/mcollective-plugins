module MCollective
  module RPC
    # A RPC::Audit plugin that sends all audit messages to a non SimpleRPC agent called
    # centralrpclog where it can then process them however it feels like
    #
    # https://github.com/puppetlabs/mcollective-plugins
    class Centralrpclog<Audit
      def audit_request(request, connection)
        begin
          config = Config.instance

          log_collective = config.pluginconf.fetch("centralrpclog.collective", config.main_collective)

          filter = Util.empty_filter
          filter["agent"] << "centralrpclog"

          req = Message.new(request, nil, {:agent => "centralrpclog", :type => :request, :collective => log_collective, :filter => filter})
          req.encode!

          Log.debug("Sending request #{req.requestid} to the #{req.agent} agent in collective #{req.collective}")

          req.publish
        rescue Exception => e
          Log.instance.error("Failed to send audit request: #{e}")
        end
      end
    end
  end
end
