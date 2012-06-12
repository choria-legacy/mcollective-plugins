module MCollective
  module Data
    class Resource_data<Base
      activate_when { File.exist?((Config.instance.pluginconf["puppetd.resourcesfile"] || "/var/lib/puppet/state/resources.txt")) }

      query do |resource|
        resourcesfile = Config.instance.pluginconf["puppetd.resourcesfile"] || "/var/lib/puppet/state/resources.txt"

        resources = File.readlines(resourcesfile).map {|l| l.chomp}
        stat = File.stat(resourcesfile)

        if resource
          result[:managed] = resources.include?(resource.downcase)
        else
          result[:managed] = false
        end

        result[:count] = resources.size
        result[:age] = Time.now.to_i - stat.mtime.to_i
      end
    end
  end
end


