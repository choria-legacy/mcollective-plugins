module MCollective
  module Agent
    class Puppetca<RPC::Agent
      metadata    :name        => "puppetca",
                  :description => "Agent to manage Puppet certificates",
                  :author      => "R.I.Pienaar",
                  :license     => "Apache 2.0",
                  :version     => "2.1",
                  :url         => "https://github.com/puppetlabs/mcollective-plugins",
                  :timeout     => 20

      def startup_hook
        @puppetca = @config.pluginconf["puppetca.puppetca"] || "/usr/sbin/puppetca"
        @cadir  = @config.pluginconf["puppetca.cadir"]   || "/var/lib/puppet/ssl/ca"
      end

      # Does what puppetca would do, deletes signed and csr
      # not just invoking puppetca since its slow.
      action "clean" do
        validate :certname, :shellsafe

        certname = request[:certname]
        signed = paths_for_cert(certname)[:signed]
        csr = paths_for_cert(certname)[:request]

        msg = []

        if has_cert?(certname)
          File.unlink(signed)
          msg << "Removed signed cert: #{signed}."
        end

        if cert_waiting?(certname)
          File.unlink(csr)
          msg << "Removed csr: #{csr}."
        end

        if msg.size == 0
          reply.fail "Could not find any certs to delete"
        else
          reply[:msg] = msg.join("  ")
        end
      end

      # revoke a cert, do the slow call to puppetca so we're 100%
      # certain we're doing the right thing
      action "revoke" do
        validate :certname, :shellsafe

        reply[:out] = run("#{@puppetca} --color=none --revoke '#{request[:certname]}'", :stdout => :output, :chomp => true)
      end

      # sign a cert if we have one waiting
      action "sign" do
        validate :certname, :shellsafe

        certname = request[:certname]

        reply.fail! "Already have a cert for #{certname} not attempting to sign again" if has_cert?(certname)

        if cert_waiting?(certname)
          reply[:out] = run("#{@puppetca} --color=none --sign '#{request[:certname]}'", :stdout => :output, :chomp => true)
        else
          reply.fail "No cert found to sign"
        end
      end

      # list all certs, signed and waiting
      action "list" do
        requests = Dir.entries("#{@cadir}/requests").grep(/pem/)
        signed = Dir.entries("#{@cadir}/signed").grep(/pem/)

        reply[:requests] = requests.map{|r| File.basename(r, ".pem")}.sort
        reply[:signed] = signed.map{|r| File.basename(r, ".pem")}.sort
      end

      # display status of a cert
      action "status" do
        validate :certname, :shellsafe

        certname = request[:certname]

        if has_cert?(certname)
          reply[:msg] = "signed"
        elsif cert_waiting?(certname)
          reply[:msg] = "awaiting signature"
        else
          reply[:msg] = "not found"
        end
      end

      private
      # checks if we have a signed cert matching certname
      def has_cert?(certname)
        File.exist?(paths_for_cert(certname)[:signed])
      end

      # checks if we have a signing request waiting
      def cert_waiting?(certname)
        File.exist?(paths_for_cert(certname)[:request])
      end

      # gets the paths to all files involved with a cert
      def paths_for_cert(certname)
        {:signed => "#{@cadir}/signed/#{certname}.pem",
          :request => "#{@cadir}/requests/#{certname}.pem"}
      end
    end
  end
end

# vi:tabstop=2:expandtab:ai:filetype=ruby
