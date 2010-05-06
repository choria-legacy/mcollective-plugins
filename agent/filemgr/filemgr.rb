require 'fileutils'

module MCollective
    module Agent
        class Filemgr<RPC::Agent

            def startup_hook
                meta[:license] = "Apache 2"

                meta[:author] = "Mike Pountney"
                meta[:version] = "0.1"
                meta[:url] = "http://mcollective.googlecode.com/"

                @timeout = 5
            end

            # Basic file touch action - create (empty) file if it doesn't exist,
            # update last mod time otherwise.
            # useful for checking if mcollective is operational, via NRPE or similar.
            def touch_action
                file = request[:file] || config.pluginconf["filemgr.touch_file"] || "/var/run/mcollective.plugin.filemgr.touch"
                begin
                    FileUtils.touch(file)
                    logger.debug ("Touched file '#{file}'")
                rescue
                    logger.warn ("Could not touch file '#{file}'")
                    reply.fail "Could not touch file '#{file}'", 1 
                end
                return
            end

            # Basic file removal action
            def remove_action
                validate :file, String  # must be a string
                validate :file, /^\//   # must be absolute

                file = request[:file]

                if ! File.exists?(file)
                    logger.debug ("Asked to remove file '#{file}', but it does not exist")
                    reply.statusmsg = "OK"
                    return
                end

                begin
                    FileUtils.rm(file)
                    logger.debug ("Removed file '#{file}'")
                    reply.statusmsg = "OK"
                rescue
                    logger.warn ("Could not remove file '#{file}'")
                    reply.fail "Could not remove file '#{file}'", 1 
                end

                return
            end

            def help
                <<-EOH
                Basic file handling agent:

                Actions:
                  touch - update last_modified (or create). Accepts :file (defaults to plugin.filemgr.touch_file or '/var/run/mcollective.plugin.filemgr.touch')
                  remove - remove a single file, does not error if nonexistant. Accepts :file
                EOH
            end

        end
    end
end

