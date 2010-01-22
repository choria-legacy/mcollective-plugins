module MCollective
    module RPC
        # A RPC::Audit plugin that sends all audit messages to a non SimpleRPC agent called
        # centrallog where it can then process them however it feels like
        class Centrallog<Audit
            def audit_request(request, connection)
                config = Config.instance
                target = Util.make_target("centrallog", :command)
                reqid = Digest::MD5.hexdigest("#{config.identity}-#{Time.now.to_f.to_s}-#{target}")
                filter = {"agent" => "centrallog"}

                req = PluginManager["security_plugin"].encoderequest(config.identity, target, request, reqid, filter)

                connection.send(target, req)
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
