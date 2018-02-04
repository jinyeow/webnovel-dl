require "uri"

require "./*"
require "./provider/*"

# `webnovel-dl` is a utility to download online fiction.
# See docs/supported_sites.md.
module WebnovelDL
  module CLI
    USAGE = <<-STRING
    Usage:
      #{PROGRAM_NAME} [OPTIONS] [URL(S)]

    STRING

    def self.run(opts : Hash)
      if ARGV.size < 1
        puts "[!] ERROR: missing url(s)."
        puts USAGE
        exit 1
      else
        ARGV.each do |url|
          uri      = URI.parse(url)
          provider = get_provider(uri.host)

          if provider.is_a?(SOL)
            if opts[:user]?
              print "Enter password: "
              opts[:password] = (STDIN.noecho(&.gets).as(String)).chomp
              puts
              provider.set_cookies(opts[:user], opts[:password])
            else
              abort <<-STRING
              [x] storiesonline.net requires a login.
                    Use: #{PROGRAM_NAME} -u USERNAME URL
              STRING
            end
          end

          id       = provider.get_id_from_url(uri.path.as(String)).as(String)
          fiction  = provider.get_fiction(id)

          begin
            raise "Couldn't get fiction." unless fiction

            if opts[:debug]?
              pp provider
              pp fiction
            end

            if opts[:output]?
              dir = opts[:output].as(String)
              Dir.mkdir(dir) unless Dir.exists? dir
              Dir.cd(dir)
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

    private def self.get_provider(host)
      case host
      when /webnovel.com/
        return Webnovel.new
      when /royalroadl/
        return RoyalRoadL.new
      when /storiesonline/
        return SOL.new
      when /fanfiction/
        return FanFictionNet.new
      when /wuxiaworld/
        return WuxiaWorld.new
      when /gravitytales/
        return GravityTales.new
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
end
