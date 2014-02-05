module MCollective
  module RPC
    # An audit plugin that logs to syslog. The facility it logs to is
    # configurable by setting plugin.rpcaudit.syslogfacility to one of:
    #   authpriv
    #   cron
    #   daemon
    #   ftp
    #   kern
    #   lpr
    #   mail
    #   news
    #   syslog
    #   user
    #   uucp
    #   local0
    #   local1
    #   local2
    #   local3
    #   local4
    #   local5
    #   local6
    #   local7

    class Systemlog<Audit
      require 'pp'
      require 'syslog'

      def audit_request(request, connection)

        if !Syslog.opened?
          facility = syslog_facility(Config.instance.pluginconf["rpcaudit.syslogfacility"] || "daemon")
          Syslog.open('mcollective-audit', Syslog::LOG_PID, facility)
        end

        Syslog.info("reqid=#{request.uniqid}: reqtime=#{request.time} caller=#{request.caller}@#{request.sender} agent=#{request.agent} action=#{request.action} data=#{request.data.pretty_print_inspect}")
      end

      def syslog_facility(facility)
        begin
          Syslog.const_get("LOG_#{facility.upcase}")
        rescue NameError => e
          Log.error("Invalid syslog facility #{facility} supplied, reverting to daemon")
          Syslog::LOG_DAEMON
        end
      end

    end
  end
end
