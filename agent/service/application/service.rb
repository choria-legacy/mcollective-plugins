module MCollective
  class Application::Service < Application
    description "Start and stop system services"

    usage <<-END_OF_USAGE
mco service [OPTIONS] [FILTERS] <SERVICE> <ACTION>

The ACTION can be one of the following:

    start   - start service
    stop    - stop service
    restart - restart or reload service
    status  - determine current status of the remote service
    END_OF_USAGE

    def print_statistics(statistics, status_counter)
      print "\n---- service summary ----\n"
      puts "           Nodes: #{statistics[:responses] +
                statistics[:noresponsefrom].size} / #{statistics[:responses]}"
      print "        Statuses: "

      if status_counter.size > 0
        status_counter.keys.sort.each do |status|
          case status
          when /^running$/
            print "started=#{status_counter[status]} "
          when /^stopped$/
            print "stopped=#{status_counter[status]} "
          when /^error$/
            print "errors=#{status_counter[status]} "
          else
            print "unknown (#{status})=#{status_counter[status]} "
          end
        end
      else
        print "No responses received"
      end

      printf("\n    Elapsed Time: %.2f s\n\n", statistics[:blocktime])
    end

    def post_option_parser(configuration)
      if ARGV.size < 2
        raise "Please specify service name and action"
      else
        service = ARGV.shift
        action  = ARGV.shift

        unless action.match(/^(start|stop|restart|status)$/)
          raise "Action can only be start, stop, restart or status"
        end

        configuration[:service] = service
        configuration[:action]  = action
      end
    end

    def validate_configuration(configuration)
      if MCollective::Util.empty_filter?(options[:filter])
        print "Do you really want to operate on " +
          "services unfiltered? (y/n): "

        STDOUT.flush

        # Only match letter "y" or complete word "yes" ...
        exit! unless STDIN.gets.strip.match(/^(?:y|yes)$/i)
      end
    end

    def main
      #
      # We have to change our process name in order to hide name of the
      # service we are looking for from our execution arguments.  Puppet
      # provider will look at the process list for the name of the service
      # it wants to manage and it might find us with our arguments there
      # which is not what we really want ...
      #
      $0 = "mco"

      status_counter = {}

      action  = configuration[:action]
      service = configuration[:service]

      rpc_service = rpcclient("service", { :options => options })

      rpc_service.send(action, { :service => service }).each do |node|

        # We want new line here ...
        puts if status_counter.size.zero? and not rpc_service.progress

        sender = node[:sender]
        data   = node[:data]

        #
        # If the status code is non-zero and data is empty then we
        # assume that something out of an ordinary had place and
        # therefore assume that there was some sort of error ...
        #
        unless node[:statuscode].zero? and data
          status = "error"
        else
          status = data["status"]
        end

        status_counter.include?(status) ?
        status_counter[status] += 1 : status_counter[status] = 1

        if rpc_service.verbose
          printf("%-40s status=%s\n", sender, status)
          puts "\t\t#{node[:statusmsg]}"
        else
          case action
          when /^start$/
            unless status.match(/^running$/)
              printf("%-40s status=%s\n", sender, status)
            end
          when /^stop$/
            unless status.match(/^stopped$/)
              printf("%-40s status=%s\n", sender, status)
            end
          when /^status$/
            printf("%-40s status=%s\n", sender, status)
          end
        end
      end

      rpc_service.disconnect

      print_statistics(rpc_service.stats, status_counter)
    end
  end
end

# vim: set ts=4 sw=4 et :

