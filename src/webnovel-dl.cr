require "option_parser"

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

  def self.main(opts : Hash of Symbol => String|Bool)
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

      if opts[:debug]
        pp provider
        pp fiction
      end

      if opts[:output]
        Dir.mkdir(opts[:output]) unless Dir.exists? opts[:output]
        Dir.cd(opts[:output])
      end

      doc = Epub.new(fiction)
      Dir.mkdir(fiction.title) unless Dir.exists? fiction.title
      Dir.cd(fiction.title)
      doc.render("#{fiction.title}.epub")
      puts "Done."
    rescue
      puts "FUCK YOU"
      exit 2
    end
  end
end

opts = {}
OptionParser.parse! do |parser|
  # parser.banner = USAGE

  parser.on("-o DIRECTORY", "--output=DIRECTORY", "Specify an output directory") { |o| opts[:output] = o }

  parser.separator

  parser.on("-D", "--debug", "Turn on debug mode.") { |d| opts[:debug] = true }

  parser.separator

  parser.on("-h", "--help", "Show this message.") { puts USAGE; exit 1 }
  parser.on("-v", "--version", "Show version information.") { puts WebnovelDL::VERSION; exit 1 }
end

pp ARGV if opts[:debug]

WebnovelDL.main(opts)
