require 'puppet'

module MCollective
  module Agent
    class Package<RPC::Agent
      metadata :name        => "Package Agent",
               :description => "Install and uninstall software packages",
               :author      => "R.I.Pienaar",
               :license     => "ASL2",
               :version     => "3.3",
               :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
               :timeout     => 180

      ["install", "update", "uninstall", "purge", "status"].each do |act|
        action act do
          validate :package, :shellsafe

          properties, output = do_pkg_action(request[:package], act.to_sym)

          reply[:output] = output

          if properties.is_a?(Hash)
            properties.keys.each do |key|
              reply[key] = properties[key].to_s
            end
          end
        end
      end

      action "yum_clean" do
        reply.fail! "Cannot find yum at /usr/bin/yum" unless File.exist?("/usr/bin/yum")

        if request[:mode]
          clean_mode = request[:mode]
        else
          clean_mode = @config.pluginconf["package.yum_clean_mode"] || "all"
        end

        if ["all", "headers", "packages", "metadata", "dbcache", "plugins", "expire-cache"].include?(clean_mode)
            reply[:exitcode] = run("/usr/bin/yum clean #{clean_mode}", :stdout => :output, :chomp => true)
        else
          reply.fail! "Unsupported yum clean mode: #{clean_mode}"
        end

        reply.fail! "Yum clean failed, exit code was #{reply[:exitcode]}" unless reply[:exitcode] == 0
      end

      action "apt_update" do
        reply.fail! "Cannot find apt-get at /usr/bin/apt-get" unless File.exist?("/usr/bin/apt-get")
        reply[:exitcode] = run("/usr/bin/apt-get update", :stdout => :output, :chomp => true)

        reply.fail! "apt-get update failed, exit code was #{reply[:exitcode]}" unless reply[:exitcode] == 0
      end

      action "checkupdates" do
        if File.exist?("/usr/bin/yum")
          reply[:package_manager] = "yum"
          yum_checkupdates_action
        elsif File.exist?("/usr/bin/apt-get")
          reply[:package_manager] = "apt"
          apt_checkupdates_action
        else
          reply.fail! "Cannot find a compatible package system to check updates for"
        end
      end

      action "yum_checkupdates" do
        reply.fail! "Cannot find yum at /usr/bin/yum" unless File.exist?("/usr/bin/yum")
        reply[:exitcode] = run("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true)

        reply[:outdated_packages] = do_yum_outdated_packages(reply[:output])
      end

      action "apt_checkupdates" do
        reply.fail! "Cannot find apt at /usr/bin/apt-get" unless File.exist?("/usr/bin/apt-get")
        reply[:exitcode] = run("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true)
        reply[:outdated_packages] = []

        if reply[:exitcode] == 0
          reply[:output].each_line do |line|
            next unless line =~ /^Inst/

            # Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []
            if line =~ /Inst (.+?) \[.+?\] \((.+?)\s(.+?)\)/
              reply[:outdated_packages] << {:package => $1.strip,
                                            :version => $2.strip,
                                            :repo => $3.strip}
            end
          end
        else
          reply.fail! "APT check-update failed, exit code was #{reply[:exitcode]}"
        end
      end

      private
      def do_pkg_action(package, action)
        begin
          pkg = ::Puppet::Type.type(:package).new(:name => package).provider

          output = ""
          properties = ""

          case action
            when :install
              output = pkg.install if [:absent, :purged].include?(pkg.properties[:ensure])

            when :update
              output = pkg.update unless [:absent, :purged].include?(pkg.properties[:ensure])

            when :uninstall
              output = pkg.uninstall unless [:absent, :purged].include?(pkg.properties[:ensure])

            when :status
              # noop

            when :purge
              output = pkg.purge

            else
              reply.fail "Unknown action #{action}"
          end

          pkg.flush
          [pkg.properties, output]
        rescue Exception => e
          reply.fail! e.to_s
        end
      end

      def do_yum_outdated_packages(packages)
        outdated_pkgs = []
        packages.strip.each_line do |line|
          # Don't handle obsoleted packages for now
          break if line =~ /^Obsoleting\sPackages/i

          pkg, ver, repo = line.split
          if pkg && ver && repo
            pkginfo = { :package => pkg.strip,
              :version => ver.strip,
              :repo => repo.strip
            }
            outdated_pkgs << pkginfo
          end
        end
        outdated_pkgs
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby
