class MCollective::Application::Puppetd<MCollective::Application
  description "Run puppet agent, get its status, and enable/disable it"
    usage <<-END_OF_USAGE
mco puppetd [OPTIONS] [FILTERS] <ACTION> [CONCURRENCY]

The ACTION can be one of the following:

    runall  - invoke a puppet run on matching nodes, making sure to only run
              CONCURRENCY nodes at a time
    runonce - invoke a puppet run on matching nodes, limiting load with
              puppet agent's --splay option
    disable - create a lockfile that prevents puppet agent from running
    enable  - remove any lockfile preventing puppet agent from running
    status  - report whether puppet agent is enabled, whether it is currently
              running, and when the last run was
    summary - return detailed resource and timing info from the last puppet run
    count   - return a total count of running, enabled, and disabled nodes
    END_OF_USAGE

  option :force,
  :description    => "Force the puppet run to happen immediately without splay",
  :arguments      => ["--force", "-f"],
  :type           => :bool

  def post_option_parser(configuration)
    if ARGV.length >= 1
      configuration[:command] = ARGV.shift
      configuration[:concurrency] = ARGV.shift.to_i or 0

      unless configuration[:command].match(/^(enable|disable|runonce|runall|status|summary|count)$/)
        raise "Action must be enable, disable, runonce, runonce, runall, status, summary, or count"
      end
    else
      raise "Please specify an action."
    end
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
          log("Failed to get node status for #{e}; continuing")
        end
      end

      return running if running < concurrency
      log("Currently #{running} nodes running; waiting") unless logged
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
          result = mc.custom_request("runonce", {:forcerun => true}, host, {"identity" => host})

          begin
            log("#{host} schedule status: #{result[0][:statusmsg]}")
          rescue
            log("#{host} returned unknown output: #{result.pretty_inspect}")
          end

          sleep 1
        end
      else
        puts("Concurrency is #{configuration[:concurrency]}; not running any nodes")
        exit 1
      end

    when "runonce"
      printrpc mc.runonce(:forcerun => configuration[:force])

    when "status"
      mc.send(configuration[:command]).each do |node|
        if node[:statuscode] == 0
          msg = node[:data][:output]
        else
          msg = node[:statusmsg]
        end

        puts "%-40s %s" % [ node[:sender], msg ]
      end

    when "summary"
      printrpc mc.last_run_summary

    when "count"
      running = enabled = total = stopped = idling = 0

      mc.progress = false
      mc.status do |resp|
        begin
          running += resp[:body][:data][:running].to_i
          enabled += resp[:body][:data][:enabled].to_i
          idling  += resp[:body][:data][:idling].to_i
          stopped += resp[:body][:data][:stopped].to_i
          total += 1
        rescue Exception => e
          log("Failed to get node status for #{e}; continuing")
        end
      end

      disabled = total - enabled

      puts
      puts "          Nodes currently enabled: #{enabled}"
      puts "         Nodes currently disabled: #{disabled}"
      puts "Nodes currently doing puppet runs: #{running}"
      puts "          Nodes currently stopped: #{stopped}"
      puts "           Nodes currently idling: #{idling}"
      puts

    else
      printrpc mc.send(configuration[:command])
    end

    mc.disconnect
    printrpcstats
  end
end
