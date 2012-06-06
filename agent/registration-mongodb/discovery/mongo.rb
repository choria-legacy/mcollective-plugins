module MCollective
  class Discovery
    class Mongo
      require 'mongo'

      class << self
        def discover(filter, timeout, limit=0, client=nil)
          config = Config.instance

          mongohost = config.pluginconf["registration.mongohost"] || "localhost"
          mongodb = config.pluginconf["registration.mongodb"] || "puppet"
          collection = config.pluginconf["registration.collection"] || "nodes"

          dbh = ::Mongo::Connection.new(mongohost).db(mongodb)
          coll = dbh.collection(collection)

          found = []

          filter.keys.each do |key|
            case key
              when "fact"
                fact_search(filter["fact"], coll, found)

              when "cf_class"
                class_search(filter["cf_class"], coll, found)

              when "agent"
                agent_search(filter["agent"], coll, found)

              when "identity"
                identity_search(filter["identity"], coll, found)
            end
          end

          # filters are combined so we get the intersection of values across
          # all matches found using fact, agent and identity filters
          found.inject(found[0]){|x, y| x & y}
        end

        def fact_search(filter, collection, found)
          filter.each do |f|
            fact = f[:fact]
            value = f[:value]
            query = nil

            case f[:operator]
              when "==", "=~"
                query = {"facts.#{fact}" => regexy_string(value)}
              when "<="
                query = {"facts.#{fact}" => {"$lte" => regexy_string(value)}}
              when ">="
                query = {"facts.#{fact}" => {"$gte" => regexy_string(value)}}
              when "<"
                query = {"facts.#{fact}" => {"$lt" => regexy_string(value)}}
              when ">"
                query = {"facts.#{fact}" => {"$gt" => regexy_string(value)}}
              when "!="
                query = {"facts.#{fact}" => {"$ne" => regexy_string(value)}}
              else
                raise "Cannot perform %s matches for facts using the mongo discovery method" % f[:operator]
            end

            raise "Failed to parse fact filter for usage with the mongo discovery method" unless query

            found << collection.find(query, :fields => ["identity"]).map{|n| n["identity"]}
          end
        end

        def class_search(filter, collection, found)
          return if filter.empty?

          matcher = filter.map {|klass| regexy_string(klass)}.uniq
          found << collection.find({'classes' => {"$all" => matcher}}, :fields => ["identity"]).map{|n| n["identity"]}
        end

        def agent_search(filter, collection, found)
          return if filter.empty?

          matcher = filter.map {|agent| regexy_string(agent)}.uniq
          found << collection.find({'agentlist' => {"$all" => matcher}}, :fields => ["identity"]).map{|n| n["identity"]}
        end

        def identity_search(filter, collection, found)
          return if filter.empty?

          matcher = filter.map {|identity| regexy_string(identity)}
          found << collection.find({'identity' => {"$in" => matcher}}, :fields => ["identity"]).map{|n| n["identity"]}
        end

        def regexy_string(string)
          if string.match("^/")
            Regexp.new(string.gsub("\/", ""))
          else
            string
          end
        end
      end
    end
  end
end
