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
          facility = get_facility(Config.instance.pluginconf["rpcaudit.syslogfacility"] || "daemon")
          Syslog.open('mcollective-audit', Syslog::LOG_PID, facility)
        end

        Syslog.info("reqid=#{request.uniqid}: reqtime=#{request.time} caller=#{request.caller}@#{request.sender} agent=#{request.agent} action=#{request.action} data=#{request.data.pretty_print_inspect}")
      end

      def get_facility(facility)
        case facility
        when 'authpriv'
          Syslog::LOG_AUTHPRIV
        when 'cron'
          Syslog::LOG_CRON
        when 'daemon'
          Syslog::LOG_DAEMON
        when 'ftp'
          Syslog::LOG_FTP
        when 'kern'
          Syslog::LOG_KERN
        when 'lpr'
          Syslog::LOG_LPR
        when 'mail'
          Syslog::LOG_MAIL
        when 'news'
          Syslog::LOG_NEWS
        when 'syslog'
          Syslog::LOG_SYSLOG
        when 'user'
          Syslog::LOG_USER
        when 'uucp'
          Syslog::LOG_UUCP
        when 'local0'
          Syslog::LOG_LOCAL0
        when 'local1'
          Syslog::LOG_LOCAL1
        when 'local2'
          Syslog::LOG_LOCAL2
        when 'local3'
          Syslog::LOG_LOCAL3
        when 'local4'
          Syslog::LOG_LOCAL4
        when 'local5'
          Syslog::LOG_LOCAL5
        when 'local6'
          Syslog::LOG_LOCAL6
        when 'local7'
          Syslog::LOG_LOCAL7
        else
          # Default to LOG_DAEMON
          Syslog::LOG_DAEMON
        end
      end
    end
  end
end
