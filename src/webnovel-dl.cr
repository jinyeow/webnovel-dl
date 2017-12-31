require "option_parser"

require "./webnovel-dl/*"
require "./webnovel-dl/provider/*"

# `webnovel-dl` is a utility to download online fiction.
# See docs/supported_sites.md.
module WebnovelDL

  def self.main(opts : Hash)
    if ARGV.size < 2
      puts "[!] ERROR: missing arguments for provider and/or book id."
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

      if opts[:debug]?
        pp provider
        pp fiction
      end

      if opts[:output]?
        Dir.mkdir(opts[:output]) unless Dir.exists? opts[:output]
        Dir.cd(opts[:output])
      end

      doc = Epub.new(fiction)
      Dir.mkdir(fiction.title) unless Dir.exists? fiction.title
      Dir.cd(fiction.title)
      doc.render("#{fiction.title}.epub")
      puts "Done."
    rescue ex
      puts "FUCK YOU"
      puts ex.message if opts[:debug]?
      exit 2
    end
  end
end

USAGE = <<-STRING
Usage:
  #{PROGRAM_NAME} [provider] [novel id]

STRING

opts = {} of Symbol => String
OptionParser.parse! do |parser|
  parser.banner = USAGE

  parser.on("-h", "--help", "Show this message.") { puts parser; exit }
  parser.on("-v", "--version", "Show version information.") {
    puts "v#{WebnovelDL::VERSION}"
    exit
  }
  
  parser.separator("\nOUTPUT OPTIONS")

  parser.on("-o DIRECTORY", "--output=DIRECTORY", "Specify an output directory") { |o|
    opts[:output] = o
  }

  parser.missing_option { puts "[!] ERROR: output argument required."; exit 2 }

  parser.separator("\nDEBUG OPTIONS")

  parser.on("-D", "--debug", "Turn on debug mode.") { |d| opts[:debug] = "1" }

  parser.invalid_option do |o|
    puts "[!] ERROR: #{o} is not a valid option."
    puts "    See webnovel-dl --help for a list of valid options."
    exit 2
  end

  # NOTE: maybe can use #unknown_args to pass along the provider and book id with the 
  #   opts Hash instead of as ARGV.
end

pp ARGV if opts[:debug]?

WebnovelDL.main(opts)

