class MCollective::Application::Pgrep<MCollective::Application
  description "Distributed Process Management"
  usage "mco pgrep <pattern> [-z]"

  option :just_zombies,
         :description => "Only list defunct processes",
         :arguments   => ["-z", "--zombies"],
         :type        => :bool

  class ::Numeric
      def bytes_to_human
          if self > 0
              units = %w{B KB MB GB TB}
              e = (Math.log(self)/Math.log(1024)).floor
              s = "%.3f " % (to_f / 1024**e)
              s.sub(/\.?0*$/, units[e])
          else
              "0 B"
          end
      end
  end

  def post_option_parser(configuration)
    if ARGV.length == 1
      configuration[:pattern] = ARGV.shift
    else
      abort "Please provide a pattern to search for"
    end
  end

  def validate_configuration(configuration)
    abort "Please provide a pattern to search for" unless configuration.include?(:pattern)
  end

  def main
    ps = rpcclient("process")

    stats = {:count => 0,
             :hosts => 0,
             :vsize => 0,
             :rss   => 0}

    ps.list(configuration).each_with_index do |result, i|
      begin
        if result[:data][:pslist].size > 0
          stats[:hosts] += 1

          puts result[:sender]

          result[:data][:pslist].each_with_index do |process, idx|
            puts "   %5s %-10s  %-15s  %s" % ["PID", "USER", "VSZ", "COMMAND"] if idx == 0
            process[:state] == "Z" ? cmdline = "[#{process[:cmdline]}]" : cmdline = process[:cmdline]

            puts "   %5d %-10s  %-15s  %s" % [process[:pid], process[:username][0,10], process[:vsize].bytes_to_human, cmdline[0,60] ] if process[:cmdline].match configuration[:pattern]

            stats[:count] += 1
            stats[:vsize] += process[:vsize]
            stats[:rss] += process[:rss] * 1024
          end

          puts
        end
      rescue => e
        STDERR.puts "Failed to get results from #{result[:sender]}: #{e.class}: #{e}"
      end
    end

    puts "   ---- process list stats ----"
    puts "        Matched hosts: #{stats[:hosts]}"
    puts "    Matched processes: #{stats[:count]}"
    puts "        Resident Size: #{stats[:rss].bytes_to_human}"
    puts "         Virtual Size: #{stats[:vsize].bytes_to_human}"

    printrpcstats
  end
end
