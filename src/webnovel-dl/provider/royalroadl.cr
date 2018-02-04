require "http/client"
require "uri"
require "xml"

require "../provider.cr"
require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class RoyalRoadL < Provider
    MAIN_URL = "http://royalroadl.com"

    def get_id_from_url(path : String) : String
      /fiction\/(\d+)/.match(path)
      $1
    end

    def get_chapter(chapter_id : String) : Chapter
      url = MAIN_URL + "/fiction/chapter/#{chapter_id}"
      res = get_and_follow(url)
      xml = XML.parse_html(res.body)

      content = xml.xpath_nodes("//body//*[contains(@class,
                                'chapter-content')]")[0].text
      content = "<p>#{content.gsub(/[\r\n]+/, "</p><p>")}</p>"
      title = xml.xpath_nodes("//body//div[contains(@class, 'col-md-5')]/h1")[0].text

      Chapter.new(title, content, chapter_id)
    end

    def get_chapter(book_id : String, chapter_id : String) : Chapter
      get_chapter(chapter_id).tap { |c| after_chapter(c) }
    end

    def get_fiction(id : String) : Fiction
      url = MAIN_URL + "/fiction/#{id}"
      res = get_and_follow(url)
      xml = XML.parse_html(res.body)

      author = xml.xpath_node("//body//span[@property='name']").as(XML::Node).text
      title = xml.xpath_node("//body//h1[@property='name']").as(XML::Node).text.strip

      fiction = Fiction.new(title, author, Array(Chapter).new).tap { |f| on_fiction(f) }

      chapters = xml.xpath_nodes("//body//tbody/tr").map do |node|
        /chapter\/(\d+)/.match(node.attributes["data-url"].text)
        get_chapter(id, $1)
      end

      fiction.tap { |f| f.chapters = chapters }
    end
  end
end
