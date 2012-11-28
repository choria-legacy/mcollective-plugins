class MCollective::Application::Puppetconf<MCollective::Application
  description "Change puppet configuration"
    usage <<-END_OF_USAGE
mco puppetconf [OPTIONS] [FILTERS] <ACTION> <NEW_VALUE>

The ACTION can be one of the following:

    environment - change the puppet agent environment
    server - change the puppet agent server 
    END_OF_USAGE

  option :dryrun,
  :description    => "Test if the change of config will work",
  :arguments      => ["--dry-run", "-n"],
  :type           => :bool

  def post_option_parser(configuration)
    if ARGV.length >= 1
      configuration[:command] = ARGV.shift
      configuration[:newval] = ARGV.shift

      unless configuration[:command].match(/^(environment|server)$/)
        raise "Action must be environment or server"
      end
    else
      raise "Please specify an action."
    end
  end

  # Prints a log statement with a time
  def log(msg)
    puts("#{Time.now}> #{msg}")
  end

  def main
    mc = rpcclient("puppetconf", :options => options)
    case configuration[:command]
    when "environment"
      printrpc mc.environment(:newval => configuration[:newval])
    when "server"
      printrpc mc.server(:newval => configuration[:newval])
    else
      printrpc mc.send(configuration[:command])
    end
    mc.disconnect
    printrpcstats
  end
end
