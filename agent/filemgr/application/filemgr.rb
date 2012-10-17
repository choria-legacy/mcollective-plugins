class MCollective::Application::Filemgr<MCollective::Application

  description "Generic File Manager Client"
  usage "Usage: mc-filemgr [--file FILE] [touch|remove|status]"
  usage "Usage: mc-filemgr [--dir DIR] list"
  
  option :file,
         :description    => "File to manage",
         :arguments      => ["--file FILE", "-f FILE"]

  option :details,
         :description    => "Show full file details",
         :arguments      => ["--details", "-d"],
         :type           => :bool

  option :directory,
         :description    => "Directory to list",
         :arguments      => "--dir DIR"

  def post_option_parser(configuration)
    configuration[:command] = ARGV.shift if ARGV.size > 0
  end

  def validate_configuration(configuration)
    configuration[:command] = "touch" unless configuration.include?(:command)
    if ['touch','remove','status'].include?(configuration[:command]) && !configuration[:file]
      raise "Action requires the file option"
    elsif configuration[:command] == "list" && (!configuration[:directory] && !configuration[:file])
      raise "Action requires the directory option"
    end
    if configuration[:directory] && configuration[:file]
      raise "Option must be file or directory, not both."
    end
  end

  def size_to_human(size)
    factor = 1024
    case 
    when size >= factor**4
      # TB
      return "%.1fT" % (size/(factor**4))
    when size >= factor**3
      # GB
      return "%.1fG" % (size/(factor**3))
    when size >= factor**2
      # MB
      return "%.1fM" % (size/(factor**2))
    when size >= factor
      # KB
      return "%.1fK" % (size/factor)
    else
      return size
    end
  end

  def main
    mc = rpcclient("filemgr", :options => options)

    case configuration[:command]
    when "remove"
      printrpc mc.remove(:file => configuration[:file])

    when "touch"
      printrpc mc.touch(:file => configuration[:file])

    when "status"
      if configuration[:details]
        printrpc mc.status(:file => configuration[:file])
      else
        mc.status(:file => configuration[:file]).each do |resp|
          printf("%-40s: %s\n", resp[:sender], resp[:data][:output] || resp[:statusmsg] )
        end
      end

    when "list"      
      # Allow the use of the file flag in place of directory
      configuration[:directory] = configuration[:file] unless configuration[:directory]
      mc.list(:dir => configuration[:directory]).each do |resp|
        if resp[:statuscode] == 0  
          printf("%-40s:\n", resp[:sender])
          if configuration[:details]
            files = resp[:data][:directory]
            uid_max = files.values.max { |a, b| a[:uid_name].length <=> b[:uid_name].length }[:uid_name].length
            gid_max = files.values.max { |a, b| a[:gid_name].length <=> b[:gid_name].length }[:gid_name].length
            files.each do |key, val|
              val[:size] = size_to_human(val[:size])
            end   
            size_max = files.values.max { |a, b| a[:size].size <=> b[:size].size}[:size].size
            files.sort_by { |key, val| key }.each do |key,val|
              uid = "%-#{uid_max}s" % val[:uid_name]
              gid = "%-#{gid_max}s" % val[:gid_name]
              size = "%-#{size_max}s" % val[:size]
              print "%5s %s %s %s %s %s\n" % ["", uid, gid, size, val[:mtime], key]
            end
          else
            files = resp[:data][:directory].keys.sort
            files.each do |key,val|
              printf("%5s%s\n", "", key)
            end
          end
        else 
          printf("%-40s: Error %s\n", resp[:sender], resp[:statuscode])
        end
      end

    else
      mc.disconnect
      puts "Valid commands are 'touch', 'remove', 'status' and 'list'"
      exit 1
    end

    mc.disconnect
    printrpcstats
  end
end
