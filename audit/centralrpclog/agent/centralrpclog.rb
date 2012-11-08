module MCollective
  module Agent
    # An agent that receives and logs RPC Audit messages sent from the accompanying Audit plugin
    class Centralrpclog
      attr_reader :timeout, :meta

      require 'pp'

      def initialize
        @timeout = 1

        @meta = {:license => "Apache License, Version 2",
                 :author => "R.I.Pienaar <rip@devco.net>",
                 :timeout => @timeout,
                 :name => "Discovery Agent",
                 :version => "0.0.1",
                 :url => "http://www.marionette-collective.org",
                 :description => "MCollective Discovery Agent"}
      end

      def handlemsg(msg, connection)
        request = msg[:body]

        logfile = Config.instance.pluginconf.fetch("centralrpclog.logfile", "/var/log/mcollective-rpcaudit.log")

        File.open(logfile, "a") do |f|
          f.puts("%s %s> %s %s caller=%s#%s agent=%s action=%s %s" % [Time.new.strftime("%D %T"), msg[:senderid], request.uniqid, Time.at(request.time).strftime("%D %T"), request.caller, request.sender, request.agent, request.action, request.data.pretty_print_inspect])
        end

        # never reply
        nil
      end
    end
  end
end
