require "colorize"

require "./model/chapter"
require "./model/fiction"

module WebnovelDL
  abstract class Provider
    abstract def get_id_from_url(path : String) : String

    abstract def get_chapter(book_id : String, chapter_id : String) : Chapter
    abstract def get_fiction(book_id : String) : Fiction

    def initialize
      @client = HTTP::Client
    end

    def after_chapter(chapter : WebnovelDL::Model::Chapter, num : Int32 | Nil = nil)
      puts "Downloading ".colorize(:green).to_s + \
        "chapter " + (num ? "#{num.to_s.rjust(4, '0')}. " : "") + \
        "#{chapter.title}".colorize(:light_magenta).to_s
    end

    def on_fiction(fiction : WebnovelDL::Model::Fiction)
      puts "Downloading ".colorize(:green).to_s + \
        "#{fiction.title}".colorize(:light_blue).to_s + \
        " by " + "#{fiction.author}".colorize(:light_red).to_s
    end
  end
end
