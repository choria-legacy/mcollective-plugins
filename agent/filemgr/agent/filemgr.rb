require 'fileutils'
require 'digest/md5'
require 'etc'

module MCollective
  module Agent
    # A basic file management agent, you can touch, remove or inspec files.
    #
    # A common use case for this plugin is to test your mcollective setup
    # as such if you just call the touch/info/remove actions with no arguments
    # it will default to the file /var/run/mcollective.plugin.filemgr.touch
    # or whatever is specified in the plugin.filemgr.touch_file setting
    class Filemgr<RPC::Agent
      metadata    :name        => "filemgr",
                  :description => "File Manager",
                  :author      => "Mike Pountney <mike.pountney@gmail.com>",
                  :license     => "Apache 2",
                  :version     => "1.1",
                  :url         => "http://www.puppetlabs.com/mcollective",
                  :timeout     => 5
      # Basic file touch action - create (empty) file if it doesn't exist,
      # update last mod time otherwise.
      # useful for checking if mcollective is operational, via NRPE or similar.
      action "touch" do
        touch
      end

      # Basic file removal action
      action "remove" do
        remove
      end

      # Basic status of a file
      action "status" do
        status
      end
      
      # Basic directory listing with file status
      action "list" do
        list
      end

      private
      def get_filename
        request[:file] || config.pluginconf["filemgr.touch_file"] || "/var/run/mcollective.plugin.filemgr.touch"
      end

      private
      def get_file_status(file = get_filename)
        results = {}
        results[:name] = file
        results[:output] = "not present"
        results[:type] = "unknown"
        results[:mode] = "0000"
        results[:present] = 0
        results[:size] = 0
        results[:mtime] = 0
        results[:ctime] = 0
        results[:atime] = 0
        results[:mtime_seconds] = 0
        results[:ctime_seconds] = 0
        results[:atime_seconds] = 0
        results[:md5] = 0
        results[:uid] = 0
        results[:gid] = 0

        if !File.exists?(file)          
          logger.debug("Asked for status of '#{file}' - it is not present")
          reply.fail!("#{file} does not exist")
        elsif !File.readable?(file)          
          logger.debug("Asked for status of '#{file}' - permission denied")
          reply.fail!("#{file} - permission denied")
        end

        logger.debug("Asked for status of '#{file}' - it is present")
        results[:output] = "present"
        results[:present] = 1

        if File.symlink?(file)
          stat = File.lstat(file)
        else
          stat = File.stat(file)
        end
      
        [:size, :mtime, :ctime, :atime, :uid, :gid].each do |item|
          results[item] = stat.send(item)
        end

        [:mtime, :ctime, :atime].each do |item|
          results["#{item}_seconds".to_sym] = stat.send(item).to_i
        end

        results[:uid_name] = Etc.getpwuid(stat.send(:uid)).name
        results[:gid_name] = Etc.getgrgid(stat.send(:gid)).name

        results[:mode] = "%o" % [stat.mode]
        results[:md5] = Digest::MD5.hexdigest(File.read(file)) if stat.file?
        results[:type] = "directory" if stat.directory?
        results[:type] = "file" if stat.file?
        results[:type] = "symlink" if stat.symlink?
        results[:type] = "socket" if stat.socket?
        results[:type] = "chardev" if stat.chardev?
        results[:type] = "blockdev" if stat.blockdev?

        return results
      end

      def status
        get_file_status.each do |key, val|
          reply[key.to_sym] = val
        end
      end

      def remove
        file = get_filename
        if ! File.exists?(file)
          logger.debug("Asked to remove file '#{file}', but it does not exist")
          reply.statusmsg = "OK"
        end

        begin
          FileUtils.rm(file)
          logger.debug("Removed file '#{file}'")
          reply.statusmsg = "OK"
        rescue
          logger.warn("Could not remove file '#{file}'")
          reply.fail!("Could not remove file '#{file}'")
        end
      end

      def touch
        file = get_filename
        begin
          FileUtils.touch(file)
          logger.debug("Touched file '#{file}'")
        rescue
          logger.warn("Could not touch file '#{file}'")
          reply.fail!("Could not touch file '#{file}'")
        end
      end

      def list
        dir = request[:dir]
        directory = {}
        if File.directory?(dir)
          begin
            Dir.foreach(dir) do |entry|
              directory[entry.to_sym] = get_file_status(File.join(dir, entry))
            end
            reply[:directory] = directory
          rescue => e
            logger.warn("Could not list directory '%s': %s" % [dir, e])
            reply.fail!("Could not list directory '%s': %s" % [dir, e])
          end
        else
          logger.debug("Asked to list directory '#{dir}', but it does not exist")
          reply.fail!("#{dir} does not exist")
        end
      end	
    end
  end
end
