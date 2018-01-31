require "http"
require "xml"
# require "uri"

module WebnovelDL
  class SOL < Provider
    MAIN_URL = "http://storiesonline.net"

    def get_id_from_url(path : String) : String
      path
    end

    def initialize
      super
    end

    def set_cookies(user : String, pw : String) : HTTP::Headers
      login_url = "https://storiesonline.net/sol-secure/login.php"

      # Login.php
      res      = @client.post(login_url + "?theusername=#{user}&thepassword=#{pw}")

      # GET /sol-secure/user/cookie_check.php?a=1 HTTP/1.1
      cookies  = HTTP::Cookies.from_headers(res.headers)
      @cookies = HTTP::Headers.new
      @cookies = cookies.add_request_headers(HTTP::Headers.new)
    end

    def get_chapter(book_id : String, chapter_id : String) : Chapter
      # res = get_and_follow(MAIN_URL + "/s/#{book_id}:#{chapter_id}")
      url = MAIN_URL + "/s/#{book_id}:#{chapter_id}"
      res = @client.get(url, @cookies)
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes("//body//div[@id='story']//article/h2")[0].text
      content = xml.xpath_nodes("//body//div[@id='story']//article//p")
                   .map(&.text).join("</p><p>")
      content = "<p>#{content.gsub(/[\r\n]+/, "</p><p>")}</p>"

      Chapter.new(title, content, chapter_id).tap do |c|
        after_chapter(c)
      end
    end

    def get_fiction(book_id : String) : Fiction
      /s\/(\d+)/.match(book_id)
      book_id = $1
      url = MAIN_URL + "/s/#{book_id}"
      res = get_and_follow(url)
      xml = XML.parse_html(res.body)

      title = xml.xpath_node("//body//header/h1").as(XML::Node).text
      author = xml.xpath_node("//body//a[@rel='author']").as(XML::Node)["href"]
                  .sub("/a/", "")

      fiction = Fiction.new(title, author, Array(Chapter).new).tap { |f| on_fiction(f) }

      chapters = xml.xpath_nodes("//body//div[@id='index-list']/span[@class='link']/a")
                    .map do |node|
        /\d+:(\d+)/.match(node["href"]) # "/s/b_id:c_id/chapter_title"
        get_chapter(book_id, $1)
      end

      fiction.tap { |f| f.chapters = chapters }
    end
  end
end
