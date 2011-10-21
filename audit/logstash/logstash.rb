module MCollective
  module RPC
    # An audit plugin that just logs to a logstash queue
    #
    # You can configure which queue it emits events to with the setting
    #
    #   plugin.logstash.target
    #
    class Logstash<Audit
      require 'json'

      def audit_request(request, connection)
        now = Time.now.utc
        now_tz = tz = now.utc? ? "Z" : now.strftime("%z")
        now_iso8601 = "%s.%06d%s" % [now.strftime("%Y-%m-%dT%H:%M:%S"), now.tv_usec, now_tz]

        audit_entry = {"@source_host" => Config.instance.identity,
          "@tags" => [],
          "@type" => "mcollective-audit",
          "@source" => "mcollective-audit",
          "@timestamp" => now_iso8601,
          "@fields" => {"uniqid" => request.uniqid,
            "request_time" => request.time,
            "caller" => request.caller,
            "callerhost" => request.sender,
            "agent" => request.agent,
            "action" => request.action,
            "data" => request.data.pretty_print_inspect},
          "@message" => "#{Config.instance.identity}: #{request.caller}@#{request.sender} invoked agent #{request.agent}##{request.action}"}

        target = Config.instance.pluginconf["logstash.target"] || "/queue/mcollective.audit"

        if connection.respond_to?(:publish)
          connection.publish(target, req)
        else
          connection.send(target, req)
        end
      end

    end
  end
end
# vi:tabstop=2:expandtab:ai
