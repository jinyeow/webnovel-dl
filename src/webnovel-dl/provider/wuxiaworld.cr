require "xml"

require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class WuxiaWorld < Provider
    MAIN_URL = "https://www.wuxiaworld.com"

    def get_id_from_url(path : String) : String
      path
    end

    def get_chapter(book_id : String, chapter_id : String) : Chapter
      # TODO
    end

    def get_fiction(book_id : String) Fiction
      # TODO
    end
  end
end
