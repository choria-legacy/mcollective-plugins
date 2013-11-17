# discovers against directory of yaml files instead of the traditional network discovery
# the input must be a directory of files as written out by the registration-monitor plugin
require 'mcollective/rpc/helpers'
require 'yaml'

module MCollective
  class Discovery
    class Registrationmonitor
      def self.parse_hosts(dir, hosts)
        data = {}
        hosts.each do |host|
          data[host] = YAML.load(File.read("#{dir}/#{host}"))
        end
        data
      end

      def self.discover(filter, timeout, limit=0, client=nil)
        newerthan = Time.now.to_i - Integer(Config.instance.pluginconf["registration.criticalage"] || 3600)

        unless client.options[:discovery_options].empty?
          directory = client.options[:discovery_options].last
        else
          raise("Need --discovery_options to a directory")
        end

        discovered = []
        Dir.new(directory).each do |file|
          next if file =~ /^\.\.?$/
          if File.mtime("#{directory}/#{file}").to_i >= newerthan
            discovered.push file
          end
        end

        discovered.map do |host|
          raise "Identities can only match /\w\.\-/, host #{host} does not match" unless host.match(/^[\w\.\-]+$/)
          host
        end

        filter['identity'].each do |identity|
          discovered = discovered.grep regexy_string(identity)
        end

        parsed_hostdata = parse_hosts(directory, discovered)

        discovered = discovered.select { |identity| parsed_hostdata[identity][:collectives].include?(client.options[:collective]) }

        filter.keys.each do |key|
          case key
            when "fact"
              discovered = fact_search(filter["fact"], discovered, parsed_hostdata)

            when "cf_class"
              discovered = class_search(filter["cf_class"], discovered, parsed_hostdata)

            when "agent"
              discovered = agent_search(filter["agent"], discovered, parsed_hostdata)

            when "identity"
          end
        end
        discovered
      end

      def self.fact_search(filter, collection, parsed_hostdata)
        filter.each do |f|
          fact = f[:fact]
          value = f[:value]
          re = regexy_string(value)

          case f[:operator]
            when "==", "=~"
              collection = collection.select { |identity| re.match(parsed_hostdata[identity][:facts][fact]) }
            when "<="
              collection = collection.select { |identity| value <= parsed_hostdata[identity][:facts][fact] }
            when ">="
              collection = collection.select { |identity| value >= parsed_hostdata[identity][:facts][fact] }
            when "<"
              collection = collection.select { |identity| value < parsed_hostdata[identity][:facts][fact] }
            when ">"
              collection = collection.select { |identity| value > parsed_hostdata[identity][:facts][fact] }
            when "!="
              collection = collection.select { |identity| !re.match(parsed_hostdata[identity][:facts][fact]) }
            else
              raise "Cannot perform %s matches for facts using the registrationmonitor discovery method" % f[:operator]
          end
        end
        collection
      end

      def self.class_search(filter, collection, parsed_hostdata)
        filter.each do |f|
          re = regexy_string(f)
          collection = collection.select { |identity| parsed_hostdata[identity][:classes].find { |klass| re.match(klass) } }
        end
        collection
      end

      def self.agent_search(filter, collection, parsed_hostdata)
        filter.each do |f|
          re = regexy_string(f)
          collection = collection.select { |identity| parsed_hostdata[identity][:agentlist].find { |klass| re.match(klass) } }
        end
        collection
      end

      def self.regexy_string(string)
        if string.match("^/")
          Regexp.new(string.gsub("\/", ""))
        else
          Regexp.new("^#{string}$")
        end
      end
    end
  end
end

