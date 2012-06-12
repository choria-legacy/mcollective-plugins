module MCollective
  module Data
    class Sysctl_data<Base
      activate_when { File.exist?("/sbin/sysctl") }

      query do |sysctl|
        shell = Shell.new("/sbin/sysctl %s" % sysctl)
        shell.runcommand

        if shell.status.exitstatus == 0
          value = shell.stdout.chomp.split(/\s*=\s*/)[1]

          if value
            value = Integer(value) if value =~ /^\d+$/
            value = Float(value) if value =~ /^\d+\.\d+$/

            result[:value] = value
          end
        end
      end
    end
  end
end
