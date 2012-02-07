module MCollective
  module Agent
    # A registration agent that places information from the meta
    # registration class into a mongo db instance.
    #
    # To get this going you need:
    #
    #  - The meta registration plugin everywhere [1]
    #  - A mongodb instance
    #  - The mongo gem installed ideally with the bson_ext extension
    #
    # The following configuration options exist:
    #  - plugin.registration.mongohost where the mongodb is default: localhost
    #  - plugin.registration.mongodb the db name default: puppet
    #  - plugin.registration.collection the collection name default: nodes
    #
    # Each document will have the following data:
    #  - fqdn - the fqdn of the sender
    #  - lastseen - last time we got data from it
    #  - facts - a collection of facts
    #  - agentlist - a collection of agents on the node
    #  - classes - a collection of classes
    #
    # A unique constraint index will be created on the fqdn of the sending
    # hosts.
    #
    # Released under the terms of the Apache 2 licence, contact
    # rip@devco.net with questions
    class Registration
      attr_reader :timeout, :meta

      def initialize
        @meta = {:license => "Apache 2",
          :author => "R.I.Pienaar <rip@devco.net>",
          :url => "https://github.com/puppetlabs/mcollective-plugins"}

        require 'mongo'

        @timeout = 2

        @config = Config.instance

        @mongohost = @config.pluginconf["registration.mongohost"] || "localhost"
        @mongodb = @config.pluginconf["registration.mongodb"] || "puppet"
        @collection = @config.pluginconf["registration.collection"] || "nodes"

        Log.instance.debug("Connecting to mongodb @ #{@mongohost} db #{@mongodb} collection #{@collection}")

        @dbh = Mongo::Connection.new(@mongohost).db(@mongodb)
        @coll = @dbh.collection(@collection)

        @coll.create_index("fqdn", {:unique => true, :dropDups => true})
      end

      def handlemsg(msg, connection)
        req = msg[:body]

        if (req.kind_of?(Array))
          Log.instance.warn("Got no facts - did you forget to add 'registration = Meta' to your server.cfg?");
          return nill
        end

        req[:fqdn] = req[:facts]["fqdn"]
        req[:lastseen] = Time.now.to_i

        # Sometimes facter doesnt send a fqdn?!
        if req[:fqdn].nil?
          Log.instance.debug("Got stats without a FQDN in facts")
          return nil
        end

        by_fqdn = {:fqdn => req[:fqdn]}
        doc_id = nil
        before = Time.now.to_f
        begin
          doc = @coll.find_and_modify(:query => by_fqdn, :update => {'$set' => req}, :new => true)
          doc_id = doc['_id']
        rescue Mongo::OperationFailure
          doc_id = @coll.insert(req, {:safe => true})
        ensure
          after = Time.now.to_f
          Log.instance.debug("Updated data for host #{req[:fqdn]} with id #{doc_id} in #{after - before}s")
        end

        nil
      end

      def help
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby

