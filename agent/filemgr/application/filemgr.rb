class MCollective::Application::Filemgr<MCollective::Application
  description "Generic File Manager Client"
  usage "Usage: mc-filemgr [--file FILE] [touch|remove|status]"

  option :file,
         :description    => "File to manage",
         :arguments      => ["--file FILE", "-f FILE"],
         :required       => true

  option :details,
         :description    => "Show full file details",
         :arguments      => ["--details", "-d"],
         :type           => :bool

  def post_option_parser(configuration)
    configuration[:command] = ARGV.shift if ARGV.size > 0
  end

  def validate_configuration(configuration)
    configuration[:command] = "touch" unless configuration.include?(:command)
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

    else
      mc.disconnect
      puts "Valid commands are 'touch', 'status', and 'remove'"
      exit 1
    end

    mc.disconnect
    printrpcstats
  end
end
