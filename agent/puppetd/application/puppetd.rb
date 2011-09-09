class MCollective::Application::Puppetd<MCollective::Application
    description "Remote Puppet daemon manager"
    usage "Usage: mc [enable|disable|runonce|runall|status|summary|count] [concurrency]"

    option :force,
        :description    => "Force the puppet run to happen immediately without splay",
        :arguments      => ["--force", "-f"],
        :type           => :bool

    option :env,
        :description        => "Environment to pass to puppet when invoking runonce or runall",
        :arguments        => ["--environment", "-e [ENV]"]

    def post_option_parser(configuration)
        if ARGV.length >= 1
            configuration[:command] = ARGV.shift
            configuration[:concurrency] = ARGV.shift.to_i or 0

            unless configuration[:command].match(/^(enable|disable|runonce|runall|status|summary|count)$/)
                raise "Command has to be enable, disable, runonce, runonce, runall, status, summary or count"
            end

            #I would think the :bool type above would take care of this
            unless configuration[:force]
                configuration[:force] = false
            end
        else
            raise "Please specify a command"
        end
    end

    def get_opts
        opts = {:forcerun => configuration[:command] == "runall" ? true : configuration[:force] }
        if configuration[:env]
            opts[:env] = configuration[:env]
            log("Passing explicit environment #{opts[:env]}")
        end
        return opts
    end

    # Prints a log statement with a time
    def log(msg)
        puts("#{Time.now}> #{msg}")
    end

    # Checks concurrent runs every second and returns once its
    # below the given threshold
    def waitfor(concurrency, client)
        logged = false

        loop do
            running = 0

            client.status do |resp|
                begin
                    running += resp[:body][:data][:running].to_i
                rescue Exception => e
                    log("Failed to get node status: #{e}, continuing")
                end
            end

            return running if running < concurrency
            log("Currently #{running} nodes running, waiting") unless logged
            logged = true
            sleep 2
        end
    end

    def main
        mc = rpcclient("puppetd", :options => options)

        case configuration[:command]
            when "runall"
                if configuration[:concurrency] > 0
                    log("Running all machines with a concurrency of #{configuration[:concurrency]}")
                    log("Discovering hosts to run")

                    mc.progress = false
                    hosts = mc.discover.sort
                    log("Found #{hosts.size} hosts")

                    # For all hosts:
                    #  - check for concurrent runs, wait till its below threshold
                    #  - do a run on the single host, regardless of if its already running
                    #  - log the output from the schedule command
                    #  - sleep a second
                    hosts.each do |host|
                        running = waitfor(configuration[:concurrency], mc)
                        log("Running #{host}, concurrency is #{running}")
                        result = mc.custom_request("runonce", get_opts, host, {"identity" => host})

                        if result.is_a?(Array)
                            log("#{host} schedule status: #{result[0][:statusmsg]}")
                        else
                            log("#{host} unknown output: #{result.pretty_inspect}")
                        end

                        sleep 1
                    end
                else
                    puts("Concurrency is #{configuration[:concurrency]}, not running any nodes")
                    exit 1
                end

            when "runonce"
                printrpc mc.runonce(get_opts)

            when "status"
                mc.send(configuration[:command]).each do |node|
                    node[:statuscode] == 0 ? msg = node[:data][:output] : msg = node[:statusmsg]

                    puts "%-40s %s" % [ node[:sender], msg ]
                end

            when "summary"
                printrpc mc.last_run_summary

            when "count"
                running = enabled = total = 0

                mc.progress = false
                mc.status do |resp|
                    begin
                        running += resp[:body][:data][:running].to_i
                        enabled += resp[:body][:data][:enabled].to_i
                        total += 1
                    rescue Exception => e
                        log("Failed to get node status: #{e}, continuing")
                    end
                end

                disabled = total - enabled

                puts
                puts "Nodes currently doing puppet runs: #{running}"
                puts "          Nodes currently enabled: #{enabled}"
                puts "         Nodes currently disabled: #{disabled}"
                puts

            else
                printrpc mc.send(configuration[:command])
        end

        mc.disconnect
        printrpcstats
    end
end
# vi:tabstop=4:expandtab:ai:filetype=ruby
