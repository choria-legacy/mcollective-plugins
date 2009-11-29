module MCollective
    module Agent
        class Puppetd
            attr_reader :timeout, :meta

            def initialize
                @log = Log.instance
                @config = Config.instance

                @timeout = 10
                @meta = {:license => "GPLv2",
                         :author => "R.I.Pienaar <rip@devco.net>",
                         :url => "http://code.google.com/p/mcollective-plugins/"}

                if @config.pluginconf.include?("puppetd.splaytime")
                    @splaytime = @config.pluginconf["puppetd.splaytime"]
                else
                    @splaytime = 0
                end

                if @config.pluginconf.include?("puppetd.lockfile")
                    @lockfile = @config.pluginconf["puppetd.lockfile"]
                else
                    @lockfile = "/var/lib/puppet/state/puppetdlock"
                end

                if @config.pluginconf.include?("puppetd.puppetd")
                    @puppetd = @config.pluginconf["puppetd.puppetd"]
                else
                    @puppetd = "/usr/sbin/puppetd"
                end
            end

            def handlemsg(msg, connection)
                command = msg[:body]

                ret = {"status" => false,
                       "output" => "unknown command"}
                
                case command
                    when "enable"
                        ret = enable

                    when "disable"
                        ret = disable

                    when "runonce"
                        ret = runonce
                end

                ret
            end

            def help
                <<-EOH
                Puppetd Agent
                ==============
    
                Agent to enable, disable and run the puppet agent
    
                Accepted Messages
                -----------------
                Input is a simple string, can be:
    
                enable     - Deletes the lock file if present
                disable    - Disable the puppetd using --disable if possible
                runonce    - Run the puppetd with --runonce, if configured with 
                             it will splay it with that amount.
    

                Configuration 
                -------------

                puppetd.splaytime - How long to splay for, no splay by default
                puppetd.lockfile  - Where to find the lock file defaults to 
                                    /var/lib/puppet/state/puppetdlock
                puppetd.puppetd   - Where to find the puppetd, defaults to 
                                    /usr/sbin/puppetd

                Returned Data
                -------------
    
                Returned data is a hash, status is boolean indicating success of the request 
                while the output is just some pretty text.
    
                {"status" => true,
                 "output" => "Already running"}
                EOH
            end

            private
            def runonce
                ret = {}

                if File.exists?(@lockfile)
                    ret = {"status" => false,
                           "output" => "Lock file exists"}
                else
                    if @splaytime > 0
                        ret = {"status" => true,
                               "output" => %x[#{@puppetd} --onetime --splaylimit #{@splaytime} --splay]}
                    else
                        ret = {"status" => true,
                               "output" => %x[#{@puppetd} --onetime]}
                    end
                end

                ret
            end

            def enable
                ret = {"status" => true,
                       "output" => "Already enabled"}

                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    if stat.zero?
                        File.unlink(@lockfile)
                        ret = {"status" => true,
                               "output" => "Lock removed"}
                    else
                        ret = {"status" => true,
                               "output" => "Currently runing"}
                    end
                end

                ret
            end

            def disable
                ret = {"status" => false,
                       "output" => "Disabled or already running"}
                
                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    stat.zero? ? ret["output"] = "Already disabled" : ret["output"] = "Currently running"
                else
                    ret = {"status" => true,
                           "output" => %x[#{@puppetd} --disable]}
                end

                ret
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
