require "option_parser"

require "./webnovel-dl/cli"

opts = {} of Symbol => String
OptionParser.parse! do |parser|
  parser.banner = WebnovelDL::CLI::USAGE

  parser.on("-h", "--help", "Show this message.") { puts parser; exit }
  parser.on("-v", "--version", "Show version information.") {
    puts "v#{WebnovelDL::VERSION}"
    exit
  }

  parser.separator("\nOUTPUT OPTIONS")

  parser.on("-o DIRECTORY", "--output=DIRECTORY", "Specify an output directory") { |o|
    opts[:output] = o
  }

  parser.on("-u USER", "--user=USER", "Provide a username to login.") do |u|
    opts[:user] = u
  end

  parser.missing_option { puts "[!] ERROR: output argument required."; exit 2 }

  parser.separator("\nDEBUG OPTIONS")

  parser.on("-D", "--debug", "Turn on debug mode.") { opts[:debug] = "1" }

  parser.separator("\nRESERVED")

  # TODO
  parser.on("-a EPUB", "--append=EPUB", "Appends the content of the URL to the EPUB.") do |a|
    opts[:append] = a
  end

  # TODO
  parser.on("-I", "--cover-image", "Specify the path to an image to use as the epub's titlepage.") do |i|
    opts[:cover_image] = i
  end

  # TODO
  parser.on("-U EPUB", "--update=EPUB", "Update the specified EPUB to the latest chapter.") do |u|
    opts[:update] = u
  end

  # TODO
  parser.on("--as-one", "Combines the content of all URLs provided into ONE epub.") do
    opts[:as_one] = "1"
  end

  parser.invalid_option do |o|
    puts "[!] ERROR: #{o} is not a valid option."
    puts "    See webnovel-dl --help for a list of valid options."
    exit 2
  end

  # NOTE: maybe can use #unknown_args to pass along the provider and book id with the
  #   opts Hash instead of as ARGV.
end

pp ARGV if opts[:debug]?

WebnovelDL::CLI.run(opts)
