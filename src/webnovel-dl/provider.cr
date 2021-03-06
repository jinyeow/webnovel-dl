require "colorize"
require "http"

require "./model/chapter"
require "./model/fiction"

alias Chapter = WebnovelDL::Model::Chapter
alias Fiction = WebnovelDL::Model::Fiction

module WebnovelDL
  abstract class Provider
    abstract def get_id_from_url(path : String) : String

    abstract def get_chapter(book_id : String, chapter_id : String) : Chapter
    abstract def get_fiction(book_id : String) : Fiction

    def initialize
      @client = HTTP::Client
    end

    protected def after_chapter(chapter : Chapter, num : Int32 | Nil = nil)
      puts "Downloading ".colorize(:green).to_s + \
        (num ? "chapter #{num.to_s.rjust(4, '0')}. " : "") + \
        "#{chapter.title}".colorize(:light_magenta).to_s
    end

    protected def on_fiction(fiction : Fiction)
      puts "Downloading ".colorize(:green).to_s + \
        "#{fiction.title}".colorize(:light_blue).to_s + \
        " by " + "#{fiction.author}".colorize(:light_red).to_s
    end

    protected def get_and_follow(url, header = nil)
      @client.get(url, header) do |response|
        loop do
          case response.status_code
          when 200..299
            return response
          when 300..399
            # new_url  = response.headers["Location"]
            new_url  = build_redirect_url(response)
            response = @client.get(new_url, header)
          else
            exit 2
          end
        end
        response
      end
    end

    protected def build_redirect_url(response) : String
      response.headers["Location"]
    end
  end
end
