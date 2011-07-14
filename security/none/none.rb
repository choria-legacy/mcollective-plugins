module MCollective
    module Security
        # A YAML based security plugin that doesnt actually secure anything
        # it just does the needed serialization.
        #
        # You should *NOT* use this for every day running, this exist mostly
        # to make development and testing a bit less painful
        class None < Base
            require 'etc'
            require 'yaml'

            # Decodes a message by unserializing all the bits etc, it also validates
            # it as valid using the psk etc
            def decodemsg(msg)
                YAML.load(msg.payload)
            end

            # Encodes a reply
            def encodereply(sender, msg, requestid, requestcallerid=nil)
                YAML.dump(create_reply(requestid, sender, msg))
            end

            # Encodes a request msg
            def encoderequest(sender, msg, requestid, filter, target_agent, target_collective)
                request = create_request(requestid, filter, msg, @initiated_by, target_agent, target_collective)

                YAML.dump(request)
            end

            # Checks the md5 hash in the request body against our psk, the request sent for validation
            # should not have been deserialized already
            def validrequest?(req)
                @stats.validated
                return true
            end

            def callerid
                "user=#{Etc.getlogin}"
            end
        end
    end
end
# vi:tabstop=4:expandtab:ai
