# -*- coding: undecided -*-
module MCollective
  module Agent
    class Packages<RPC::Agent
      metadata :name        => "SimpleRPC Agent For Multi-Package Management",
               :description => "Agent to manage multiple packages",
               :author      => "Jens Braeuer <jens@numberfour.eu>",
               :license     => "ASL2",
               :version     => "1.3",
               :url         => "https://github.com/numberfour/mcollective-plugins",
               :timeout     => 600

      #
      # status codes:
      #   0 - ok
      #   1 - package not found, unable to install, requested version not found
      #
      # request = {
      #   data = {
      #     :action => "uptodate"
      #     :packages => {
      #        "foo" => { :version => "1.0", :release => "1.el6" },
      #        "bar" => { :version => nil,   :release => nil     },
      #        "fox" => { :version => "1.0", :release => "1.el6" }
      #     }
      #   }
      # }
      #
      # reply = {
      #   data = {
      #     :status => 0..1 - 0=ok, 1=error
      #     :packages => {
      #        "foo" => { :version => "1.1", :release => "1.el6", :status => 1 },
      #        "bar" => { :version => "2.0", :release => "4001",  :status => 0 },
      #        "fox" => { :version => nil,   :release => nil,     :status => 1 },
      #     }
      #   }
      # }
      #

      ["uptodate"].each do |act|
        action act do
          begin
            do_pkg_validate(request["packages"])
            do_pkg_action(act.to_sym, request["packages"])
          rescue => e
            puts e
            raise
          end
        end
      end

      private
      def log(msg)
        open("/tmp/log", 'a') { |fd| fd.write ">> #{Time.now} - #{msg}\n" }
      end
      def e_str(e)
        "#{e.message} // #{e.class} \n\t#{e.backtrace.join("\n\t")}"
      end

      def do_pkg_validate(packages)
        raise "Packages must be a Array. Found #{packages.class}" unless packages.is_a? Array
        packages.each do |item|
          raise "Packages item must be a Hash. Found #{item.class}" unless item.is_a? Hash
          raise "Package keys not as expected. Found #{item.keys}" unless item.keys.sort == ["name", "version", "release"].sort
          item.each do |k,v|
            raise "Key not a string: #{k}" unless item[v].is_a? String or item[v].nil?
          end
          raise "Release given, but version missing." if item["version"].nil? and not item["release"].nil?
        end
      end

      def initialize_reply
        reply["status"] = 0
        reply["packages"] = []
      end

      def update_reply(package)
        reply["packages"] << package
      end

      def calculate_status
        unless reply["packages"].empty?
          reply["status"] = reply["packages"].map { |item| item["status"] }.max
        end
      end

      def apt_update
        stdout = []
        exitcode = run("/usr/bin/apt-get update", :stdout => stdout, :chomp => true)
        log "Package list refreshed: #{stdout}"
        raise "apt-get update failed, exit code was #{exitcode}" unless exitcode == 0
      end

      def yum_clean_expirecache
        stdout = []
        exitcode = run("/usr/bin/yum clean expire-cache", :stdout => stdout, :chomp => true)
        log "Package list refreshed: #{stdout}"
        raise "Yum clean failed, exit code was #{exitcode}" unless exitcode == 0
      end

      def fresh_package_list
        if File.exist? "/usr/bin/yum"
          yum_clean_expirecache
        elsif File.exist? "/usr/bin/apt-get"
          apt_update
        else
          raise "Neither apt-get nor yum found."
        end
      end

      def as_requested(is, should)
        res = true
        if is["version"].nil? or is["release"].nil?
          res = false
        elsif not should["version"].nil? and should["version"] != is["version"]
          res = false
        elsif not should["release"].nil? and should["release"] != is["release"]
          res = false
        end
        log "as_requested(#{is.inspect} <-> #{should.inspect}) = #{res}"
        return res
      end

      def initialize_pkg_reply(package)
        pkg_reply = {
          "name" => package["name"],
          "status" => 1
        }
        return pkg_reply
      end

      def update_pkg_reply(pkg_reply, pkg, should)
        pkg.flush
        pkg_reply["version"] = pkg.properties[:version]
        pkg_reply["release"] = pkg.properties[:release]
        pkg_reply["status"] = as_requested(pkg_reply, should) ? 0 : 1
        log "pkg_reply is: #{pkg_reply.inspect}"
      end

      def uptodate_package(should)
        pkg_reply = initialize_pkg_reply(should)
        pkg_version = [ should["version"], should["release"] ].reject { |i| i.nil? }.join("-")
        pkg_ensure = should["version"].nil? ? :latest : pkg_version
        pkg_name = should["name"]

        logger.info "Handle: ensure => #{pkg_ensure}, name => #{pkg_name}: #{should.inspect}"
        begin
          pkg = ::Puppet::Type.type(:package).new(:name => pkg_name, :ensure => pkg_ensure).provider
          pkg.install
        rescue Puppet::ExecutionFailure => e
          logger.warn "Install failed: #{e_str(e)}"
        end
        update_pkg_reply(pkg_reply, pkg, should)
        return pkg_reply
      end

      def do_pkg_action(action, packages_should)
        begin
          require 'puppet'
          fresh_package_list
          initialize_reply

          packages_is = packages_should.map { |p| uptodate_package p }
          reply["packages"] = packages_is
          log "#{reply.inspect}"
          log "#{reply["packages"].inspect}"

          calculate_status
        rescue Exception => e
          log e_str(e)
          reply.fail e.to_s
        end
      end

    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby
