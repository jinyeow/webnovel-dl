require "./webnovel-dl/*"
require "./webnovel-dl/provider/webnovel.cr"

# TODO: Write documentation
module WebnovelDL

  USAGE = <<-STRING
  Webnovel-dl

  Usage:
    webnovel-dl <provider> <id>

  Options:
    --help     Show this message.
    --version  Show version.
  STRING

  def self.main
    if ARGV.size < 1
      puts USAGE
      exit 1
    else
      case ARGV.shift
      when "webnovel.com"
        provider = WebnovelDL::Webnovel.new
        fiction  = provider.get_fiction(ARGV.shift)
      else
        puts <<-ERROR
        [!] ERROR: Not a valid provider.
            
            Choose from:
              - webnovel.com
        ERROR
        exit 1
      end
    end

    begin
      # TODO: convert/render content into epub format
      pp provider
      pp fiction
    rescue
      puts "FUCK YOU"
      exit 2
    end
  end
end

WebnovelDL.main
