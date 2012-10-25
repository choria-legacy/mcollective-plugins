# Dancers Shell Application
class MCollective::Application::Dsh<MCollective::Application
  description "Use discovery for Dancers Shell"

  usage "mco dsh [filters] -- (dsh commands)"

  def main
    mc = rpcclient("rpcutil")

    raise "No hosts discovered" if mc.discover.empty?

    machines = mc.discover.join(",")

    exec "dsh", "-m", machines, *ARGV
  end
end
