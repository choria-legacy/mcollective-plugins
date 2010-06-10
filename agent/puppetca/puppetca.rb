module MCollective
    module Agent
        class Puppetca<RPC::Agent
            def startup_hook
                meta[:license] = "Apache License 2.0"
                meta[:author] = "R.I.Pienaar"
                meta[:version] = "1.0"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 20

                @puppetca = @config.pluginconf["puppetca.puppetca"] || "/usr/sbin/puppetca"
                @cadir  = @config.pluginconf["puppetca.cadir"]   || "/var/lib/puppet/ssl/ca"
            end

            # Does what puppetca would do, deletes signed and csr
            # not just invoking puppetca since its slow.
            def clean_action
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
                     reply[:msg] = "Could not find any certs to delete"
                 else
                    reply[:msg] = msg.join("  ")
                 end
            end

            # revoke a cert, do the slow call to puppetca so we're 100%
            # certain we're doing the right thing
            def revoke_action
                 validate :certname, :shellsafe

                 reply[:out] = %x[#{@puppetca} --color=none --revoke '#{request[:certname]}']
            end

            # sign a cert if we have one waiting
            def sign_action
                 validate :certname, :shellsafe

                 certname = request[:certname]

                 fail! "Already have a cert for #{certname} not attempting to sign again" if has_cert?(certname)

                 if cert_waiting?(certname)
                     reply[:out] = %x[#{@puppetca} --color=none --sign '#{request[:certname]}']
                 else
                     reply[:out] = "No cert found to sign"
                 end
            end

            # list all certs, signed and waiting
            def list_action
                reply[:certs] = {}

		requests = Dir.entries("#{@cadir}/requests").grep(/pem/)
		signed = Dir.entries("#{@cadir}/signed").grep(/pem/)


                reply[:certs][:requests] = requests.map{|r| File.basename(r, ".pem")}
                reply[:certs][:signed] = signed.map{|r| File.basename(r, ".pem")}
            end

            def help
                <<-EOH
                EOH
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

# vi:tabstop=4:expandtab:ai:filetype=ruby
