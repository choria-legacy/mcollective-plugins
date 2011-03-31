module MCollective
    class Application::Nettest < Application
        description "Network tests from a mcollective host"

        usage <<-END_OF_USAGE
mco nettest [OPTIONS] [FILTERS] <ACTION> <HOST NAME> [PORT]

The ACTION can be one of the following:

    ping    - return round-trip time between this and remote host
    connect - check connectivity of remote host on specific port
        END_OF_USAGE

        def print_statistics(statistics, action_statistics, type)
            print "\n---- nettest summary ----\n"
            puts "           Nodes: #{statistics[:responses] +
                statistics[:noresponsefrom].size} / #{statistics[:responses]}"
            print "         Results: "

            if action_statistics.size > 0
                case type
                    when /^ping$/
                        times = action_statistics[:ping]

                        sum     = times.inject(0) { |v, i| v + i }
                        average = sum / times.size.to_f

                        printf("replies=%d, maximum=%.3f ms, " +
                            "minimum=%.3f ms, average=%.3f ms", times.size,
                            times.max, times.min, average)

                    when /^connect$/
                        printf("connected=%d, connection refused=%d, " +
                            "timed out=%d", action_statistics[:connect][0],
                            action_statistics[:connect][1],
                            action_statistics[:connect][2])
                end
            else
                print "No responses received"
            end

            printf("\n    Elapsed Time: %.2f s\n\n", statistics[:blocktime])
        end

        def post_option_parser(configuration)
            if ARGV.size < 2
                raise "Please specify an action and optional arguments"
            else
                #
                # We trust that validation will be handled correctly
                # as per accompanying DDL file ...
                #
                action = ARGV.shift

                host_name   = ARGV.shift
                remote_port = ARGV.shift

                unless action.match(/^(ping|connect)$/)
                    raise "Action can only to be ping or connect"
                end

                case action
                    when /^ping$/
                        arguments = { :fqdn => host_name }
                    when /^connect$/
                        arguments = { :fqdn => host_name,
                                      :port => remote_port }
                end

                configuration[:action]    = action
                configuration[:arguments] = arguments
            end
        end

        def validate_configuration(configuration)
            #
            # We have to ask this question because you do NOT want
            # your entire network of bazillion machines to simply
            # go and hammer some poor remote host ...  You may get
            # your network blocked or whatnot, and that would be
            # quite an unpleasant thing to have place so better to
            # be sorry and safe ...
            #
            if MCollective::Util.empty_filter?(options[:filter])
                print "Do you really want to perform network " +
                    "tests unfiltered? (y/n): "

                STDOUT.flush

                # Only match letter "y" or complete word "yes" ...
                exit! unless STDIN.gets.strip.match(/^(?:y|yes)$/i)
            end
        end

        def main
            action_statistics = {}

            action    = configuration[:action]
            arguments = configuration[:arguments]

            rpc_nettest = rpcclient("nettest", { :options => options })

            rpc_nettest.send(action, arguments).each do |node|

                # We want new line here ...
                puts if action_statistics.size.zero? and not rpc_nettest.progress

                sender = node[:sender]
                data   = node[:data]

                #
                # If the status code is non-zero and data is empty then we
                # assume that something out of an ordinary had place and
                # therefore assume that there was some sort of error ...
                #
                unless node[:statuscode].zero? and data
                    result = "error"
                else
                    result = data[:rtt] || data[:connect]
                end

                case action
                    when /^ping$/
                        action_statistics[:ping] ||= []

                        if result.match(/^[0-9\.]+$/)
                            action_statistics[:ping] << result.to_f
                            result = sprintf("%.3f", result)
                        else
                            action_statistics[:ping] << 0.0
                        end

                        if rpc_nettest.verbose
                            printf("%-40s time=%s\n", sender, result)
                            puts "\t\t#{node[:statusmsg]}"
                        else
                            printf("%-40s time=%s\n", sender, result)
                        end

                    when /^connect$/
                        action_statistics[:connect] ||= [ 0, 0, 0 ]

                        # This is to be in line with the usual format of output ...
                        result = result.tr("A-Z", "a-z")

                        case result
                            when /^connected$/
                                action_statistics[:connect][0] += 1
                            when /refused$/
                                action_statistics[:connect][1] += 1
                            when /timeout$/
                                action_statistics[:connect][2] += 1
                        end

                        if rpc_nettest.verbose
                            printf("%-40s status=%s\n", sender, result)
                            puts "\t\t#{node[:statusmsg]}"
                        else
                            printf("%-40s status=%s\n", sender, result)
                        end
                end
            end

            rpc_nettest.disconnect

            print_statistics(rpc_nettest.stats, action_statistics, action)
        end
    end
end

# vim: set ts=4 sw=4 et :
