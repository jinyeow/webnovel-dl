require "option_parser"
require "uri"

require "./webnovel-dl/*"
require "./webnovel-dl/provider/*"

# `webnovel-dl` is a utility to download online fiction.
# See docs/supported_sites.md.
module WebnovelDL
  def self.main(opts : Hash)
    if ARGV.size < 1
      puts "[!] ERROR: missing url(s)."
      puts USAGE
      exit 1
    else
      ARGV.each do |url|
        uri      = URI.parse(url)
        provider = get_provider(uri.host)
        id       = provider.get_id_from_url(uri.path.as(String))
        fiction  = provider.get_fiction(id)

        begin
          raise "Couldn't get fiction." unless fiction

          if opts[:debug]?
            pp provider
            pp fiction
          end

          if opts[:output]?
            # TODO: replace whitespace with underscores
            Dir.mkdir(opts[:output]) unless Dir.exists? opts[:output]
            Dir.cd(opts[:output])
          end

          Dir.mkdir(fiction.title) unless Dir.exists? fiction.title
          Dir.cd(fiction.title)
          doc = Epub.new(fiction)
          doc.render("#{fiction.title}.epub")
          puts "Done."
        rescue ex
          puts "FUCK YOU"
          puts ex.message if opts[:debug]?
          exit 2
        end
      end
    end
  end

  def self.get_provider(host)
    case host
    when /webnovel.com/
      return Webnovel.new
    when /royalroadl/
      return RoyalRoadL.new
    else
      puts <<-ERROR
      [!] ERROR: Not a valid provider.
          
          Choose from:
            - webnovel.com
            - royalroadl.com
      ERROR
      exit 1
    end
  end
end

USAGE = <<-STRING
Usage:
  #{PROGRAM_NAME} [OPTIONS] [URL(S)]

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

  # TODO
  parser.on("-a EPUB", "--append=EPUB", "Appends the content of the URL to the EPUB.") do |a|
    opts[:append] = a
  end

  # TODO
  parser.on("--as-one", "Combines the content of all URLs provided into ONE epub.") do
    opts[:as_one] = "1"
  end

  # TODO
  parser.on("-I", "--cover-image", "Specify the path to an image to use as the epub's titlepage.") do |i|
    opts[:cover_image] = i
  end

  # TODO
  parser.on("-u EPUB", "--update=EPUB", "Update the specified EPUB to the latest chapter.") do |u|
    opts[:update] = u
  end

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

