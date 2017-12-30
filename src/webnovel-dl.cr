require "./webnovel-dl/*"
require "./webnovel-dl/provider/*"

# `webnovel-dl` is a utility to download online fiction.
# See docs/supported_sites.md.
module WebnovelDL

  USAGE = <<-STRING
  Webnovel-dl

  Usage:
    #{PROGRAM_NAME} <provider> <id>

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
        provider = Webnovel.new
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
      raise "Couldn't get fiction." unless fiction

      pp provider
      pp fiction

      doc = Epub.new(fiction)
      Dir.mkdir(fiction.title) unless Dir.exists? fiction.title
      Dir.cd(fiction.title) { doc.render("#{fiction.title}.epub") }
      puts "Done."
    rescue
      puts "FUCK YOU"
      exit 2
    end
  end
end

WebnovelDL.main
