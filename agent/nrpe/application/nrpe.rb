class MCollective::Application::Nrpe<MCollective::Application
  description "Client to the Nagios Remote Plugin Execution system"
  usage "Usage: nrpe <check_name>"

  def post_option_parser(configuration)
    configuration[:command] = ARGV.shift if ARGV.size > 0
  end

  def validate_configuration(configuration)
    raise "Please specify a check name" unless configuration.include?(:command)
  end

  def main
    nrpe = rpcclient("nrpe")

    stats = [0, 0, 0, 0]
    statuscodes = [0]

    nrpe_results = nrpe.runcommand(:command => configuration[:command])

    puts

    nrpe_results.each do |result|
      if result[:statuscode] == 0
        exitcode = result[:data][:exitcode].to_i
        statuscodes << exitcode
      else
        exitcode = 1
        statuscodes << 1
      end

      if exitcode >=0 and exitcode < 4
        stats[exitcode] += 1
      end

      if nrpe.verbose
        printf("%-40s status=%s\n", result[:sender], result[:statusmsg])
        printf("    %-40s\n\n", result[:data][:output])
      else
        if [1,2,3].include?(exitcode)
          printf("%-40s status=%s\n", result[:sender], result[:statusmsg])
          printf("    %-40s\n\n", result[:data][:output]) if result[:data][:output]
        end
      end
    end

    puts

    # Nodes that don't respond are UNKNOWNs
    if nrpe.stats[:noresponsefrom].size > 0
      stats[3] += nrpe.stats[:noresponsefrom].size
      statuscodes << 3
    end

    printrpcstats :caption => "#{configuration[:command]} NRPE results"

    printf("\nNagios Statusses:\n") if nrpe.verbose
    printf("              OK: %d\n", stats[0])
    printf("         WARNING: %d\n", stats[1])
    printf("        CRITICAL: %d\n", stats[2])
    printf("         UNKNOWN: %d\n", stats[3])
  end
end
