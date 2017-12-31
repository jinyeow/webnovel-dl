require "colorize"

require "./model/chapter"
require "./model/fiction"

module WebnovelDL
  abstract class Provider
    abstract def get_chapter(book_id : String, chapter_id : String) : Chapter
    abstract def get_fiction(book_id : String) : Fiction

    def after_chapter(chapter : WebnovelDL::Model::Chapter, num : Int32 | String = "")
      puts "Downloading ".colorize(:green).to_s + \
        "chapter " + (num.is_a?(Int32) ? "#{num.to_s.rjust(4, '0')}. " : num) + \
        "#{chapter.title}".colorize(:light_magenta).to_s
    end

    def on_fiction(fiction : WebnovelDL::Model::Fiction)
      puts "Downloading ".colorize(:green).to_s + \
        "#{fiction.title}".colorize(:light_blue).to_s + \
        " by " + "#{fiction.author}".colorize(:light_red).to_s
    end
  end
end
