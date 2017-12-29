require "http"
require "json"

require "../provider"
require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class Webnovel < Provider
    MAIN_URL = "https://www.webnovel.com"

    def initialize
      @client   = HTTP::Client
      res      = @client.get(MAIN_URL)

      @cookies = uninitialized HTTP::Cookies
      @cookies = res.cookies

      @csrf    = uninitialized String
      @csrf    = @cookies["_csrfToken"].value
    end

    def get_chapter(book_id : String, chapter_id : String)
      url     = get_content_url(book_id, chapter_id)
      data    = get_json(url)

      title   = data["data"]["chapterInfo"]["chapterName"].to_s
      id      = data["data"]["chapterInfo"]["chapterId"].to_s
      content = data["data"]["chapterInfo"]["content"].to_s

      content = "<p>#{content.gsub("\r\n", "</p><p>")}</p>"

      WebnovelDL::Model::Chapter.new(title, content, id).tap { |c| after_chapter(c) }
    end

    def get_fiction(book_id : String)
      url      = get_chapter_url(book_id)
      data     = get_json(url)

      chapters = data["data"]["chapterItems"]
      title    = data["data"]["bookInfo"]["bookName"].to_s

      url      = get_content_url(book_id, chapters.first["chapterId"].to_s)
      author   = get_json(url)["data"]["bookInfo"]["authorName"].to_s

      chapters = chapters.map do |chap|
        get_chapter(book_id, chap["chapterId"].to_s)
      end
      WebnovelDL::Model::Fiction.new(title, author, chapters).tap { |f| on_fiction(f) }
    end

    private def get_json(url : String)
      res = @client.get(url)
      body = res.body
      JSON.parse(body)
    end

    private def get_content_url(book_id : String, chapter_id : String) 
      "https://www.webnovel.com/apiajax/chapter/GetContent?\
        _csrfToken=#{@csrf}&bookId=#{book_id}&chapterId=#{chapter_id}"
    end

    private def get_chapter_url(book_id : String)
      "https://www.webnovel.com/apiajax/chapter/GetChapterList\
        _csrfToken=#{@csrf}&bookId=#{book_id}"
    end
  end
end
