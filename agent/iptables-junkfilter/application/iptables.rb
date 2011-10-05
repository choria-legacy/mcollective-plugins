class MCollective::Application::Iptables<MCollective::Application
  description "Linux IP Tables Junkfilter Client"
  usage "iptables [block|unblock|isblocked] 1.2.3.4"

  option :silent,
  :description    => "Do not wait for results",
  :arguments      => "-s",
  :type           => :bool

  def post_option_parser(configuration)
    if ARGV.size == 2
      configuration[:command] = ARGV.shift
      configuration[:ipaddress] = ARGV.shift
    end
  end

  def validate_configuration(configuration)
    raise "Command should be one of block, unblock or isblocked" unless configuration[:command] =~ /^block|unblock|isblocked$/

    require 'ipaddr'
    ip = IPAddr.new(configuration[:ipaddress])
    raise "#{configuration[:ipaddress]} should be an ipv4 address" unless ip.ipv4?
  end

  def main
    iptables = rpcclient("iptables")

    if configuration[:silent]
      puts "Sent request " << iptables.send(configuration[:command], {:ipaddr => configuration[:ipaddress], :process_results => false})
    else
      iptables.send(configuration[:command], {:ipaddr => configuration[:ipaddress]}).each do |node|
        if iptables.verbose
          printf("%-40s %s\n", node[:sender], node[:statusmsg])
          puts "\t\t#{node[:data][:output]}" if node[:data][:output]
        else
          case configuration[:command]
          when /^block|unblock/
            printf("%-40s %s\n", node[:sender], node[:statusmsg]) unless node[:statuscode] == 0
          when "isblocked"
            printf("%-40s %s\n", node[:sender], node[:data][:output])
          end
        end
      end

      printrpcstats
    end
  end
end

# vi:tabstop=2:expandtab:ai
