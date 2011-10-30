#!/usr/bin/env ruby

# Nagios plugin to check mcollective if the registration-monitor
# is in use.
#
# https://github.com/puppetlabs/mcollective-plugins

require 'getoptlong'

opts = GetoptLong.new(
                      [ '--directory', '-d', GetoptLong::REQUIRED_ARGUMENT],
                      [ '--interval', '-i', GetoptLong::REQUIRED_ARGUMENT],
                      [ '--verbose', '-v',  GetoptLong::NO_ARGUMENT]
                      )

dir = "/var/tmp/mcollective"
interval = 300
total = 0
old = 0
verbose = false

opts.each do |opt, arg|
  case opt
  when '--directory'
    dir = arg
  when '--interval'
    interval = arg.to_i
  when '--verbose'
    verbose = true
  end
end

hosts = [ ]

Dir.open(dir) do |files|
  files.each do |f|
    next if f.match /^\./

    fage = File.stat("#{dir}/#{f}").mtime.to_i

    total += 1

    if (Time.now.to_i - fage) > interval + 30
      hosts.push f if verbose
      old += 1
    end
  end
end

if old > 0
  if verbose
    failed = hosts.join(', ')
    puts("CRITICAL: #{old} / #{total} hosts not checked in within #{interval} seconds - failed: #{failed}| totalhosts=#{total} oldhosts=#{old} currenthosts=#{total - old}")
  else
    puts("CRITICAL: #{old} / #{total} hosts not checked in within #{interval} seconds| totalhosts=#{total} oldhosts=#{old} currenthosts=#{total - old}")
  end

  exit 2
else
  puts("OK: #{total} / #{total} hosts checked in within #{interval} seconds| totalhosts=#{total} oldhosts=#{old} currenthosts=#{total - old}")
  exit 0
end

