class MCollective::Application::Package<MCollective::Application
  description "Install and uninstall software packages"
    usage <<-END_OF_USAGE
mco package [OPTIONS] <ACTION> <PACKAGE>"

The ACTION can be one of the following:

    install   - install PACKAGE
    update    - update PACKAGE
    uninstall - uninstall PACKAGE
    purge     - uninstall PACKAGE and purge related config files
    status    - determine whether PACKAGE is installed, and report its version
    END_OF_USAGE

  def post_option_parser(configuration)
    if ARGV.length == 2
      configuration[:action] = ARGV.shift
      configuration[:package] = ARGV.shift

      unless configuration[:action] =~ /^(install|update|uninstall|purge|status)$/
        puts("Action must be install, update, uninstall, purge, or status.")
        exit 1
      end
    else
      puts("Please specify an action and a package.")
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
        if resp[:data][:version]
          version = "%s-%s" % [ resp[:data][:version], resp[:data][:release] ]
        elsif resp[:data][:ensure]
          version = resp[:data][:ensure]
        end

        versions.include?(version) ? versions[version] += 1 : versions[version] = 1

        if resp[:data][:name]
          printf("%-40s version = %s-%s\n", resp[:sender], resp[:data][:name], version)
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
# vi:tabstop=2:expandtab:ai
