require 'rubygems'
require 'net/ping'
require 'socket'
require 'timeout'

module MCollective
  module Agent
    class Nettest<RPC::Agent
      metadata    :name        => "Ping",
                  :description => "Agent to do network tests from a mcollective host",
                  :author      => "Dean Smith",
                  :license     => "BSD",
                  :version     => "2.1",
                  :url         => "http://github.com/deasmi",
                  :timeout     => 60

      action "ping" do
        validate :fqdn, String

        fqdn = request[:fqdn]

        icmp = Net::Ping::ICMP.new(fqdn)

        if icmp.ping? then
          reply[:rtt] = (icmp.duration * 1000).to_s
        else
          reply[:rtt] = "Host did not respond"
        end
      end

      action "connect" do
        validate :fqdn, String
        validate :port, String

        fqdn = request[:fqdn]
        port = Integer(request[:port])

        begin
          Timeout::timeout(2) do

            begin
              t = TCPSocket.new(fqdn, port)
              t.close
              reply[:connect] = "Connected"
            rescue
              reply[:connect] = "Connection Refused"
            end
          end
        rescue Timeout::Error
          reply[:connect] = "Connection timeout"
        end
      end
    end
  end
end
