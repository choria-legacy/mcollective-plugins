class MCollective::Application::Packages<MCollective::Application
  description "Generic Package Manager"
    usage <<-END_OF_USAGE
mco packages [OPTIONS] <ACTION> <PACKAGE> <PACKAGE> ..."

The ACTION can be one of the following:

    uptodate  - install/downgrade/update PACKAGE

PACKAGES can be in the form NAME[/VERSION[/REVISION]]

    examples would be:
        - "yum"
        - "yum/3.2.29"
        - "yum/3.2.29/1.el6"

    END_OF_USAGE

  option :batch,
    :description => "Batch-mode. Don't ask for confirmation",
    :arguments => ["--batch"],
    :type => :bool

  def post_option_parser(configuration)
    if ARGV.length < 2
      raise "Please specify action and one or more packages"
    end

    configuration[:action] = ARGV.shift
    unless configuration[:action] =~ /^(uptodate)$/
      raise "Action has to be uptodate"
    end

    configuration[:packages] = ARGV.map do |elem|
      items = elem.split("/")
      raise "Package must be given as <name>/[<version>[/<release>]]" unless (1..3) === items.length
      Hash[[:name, :version, :release].zip(items)]
    end
  end

  def validate_configuration(configuration)
    if MCollective::Util.empty_filter?(options[:filter]) and not configuration[:batch]
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
# vi:tabstop=2:expandtab:ai
