class MCollective::Application::Package<MCollective::Application
    description "Generic Package Manager"
    usage "Usage: mc package [options] action package"

    def post_option_parser(configuration)
        if ARGV.length == 2
            configuration[:action] = ARGV.shift
            configuration[:package] = ARGV.shift

            unless configuration[:action] =~ /^(install|update|uninstall|purge|status)$/
                puts("Action has to be install, update, uninstall, purge or status")
                exit 1
            end
        else
            puts("Please specify a package and action")
            exit 1
        end
    end

    def validate_configuration(configuration)
        if MCollective::Util.empty_filter?(options[:filter])
            print("Do you really want to operate on packages unfiltered? (y/n): ")
            STDOUT.flush

            exit unless STDIN.gets.chomp =~ /^y$/
        end
    end

    def summarize(stats, versions)
        puts("\n---- package agent summary ----")
        puts("           Nodes: #{stats[:discovered]} / #{stats[:responses]}")
        print("        Versions: ")

        puts versions.keys.sort.map {|s| "#{versions[s]} * #{s}" }.join(", ")

        printf("    Elapsed Time: %.2f s\n\n", stats[:blocktime])
    end

    def main
        pkg = rpcclient("package", :options => options)

        versions = {}

        pkg.send(configuration[:action], {:package => configuration[:package]}).each do |resp|
            status = resp[:data][:properties]

            if resp[:statuscode] == 0
                if status.include?(:version)
                    version = "#{status[:version]}-#{status[:release]}"
                elsif status.include?(:ensure)
                    version = status[:ensure].to_s
                end

                versions.include?(version) ? versions[version] += 1 : versions[version] = 1

                if status[:name]
                    printf("%-40s version = %s-%s\n", resp[:sender], status[:name], version)
                else
                    printf("%-40s version = %s\n", resp[:sender], version)
                end
            else
                printf("%-40s error = %s\n", resp[:sender], resp[:statusmsg])
            end
        end

        summarize(pkg.stats, versions)
    end
end
# vi:tabstop=4:expandtab:ai
