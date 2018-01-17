require "xml"

require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class WuxiaWorld < Provider
    MAIN_URL = "https://www.wuxiaworld.com"

    def get_id_from_url(path : String) : String
      path
    end

    def get_chapter(book_id : String, chapter_id : String) : WebnovelDL::Model::Chapter
      chap_url = MAIN_URL + "/#{book_id}/#{chapter_id}"

      res = follow_redirect_and_get(chap_url)
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes(
        "//body//header//h1[@class='entry-title']"
      )[0].text
      content = xml.xpath_nodes("//body//div[@itemprop='articleBody']/*")
                   .to_a[1..-1]
                   .map(&.text)
                   .join("</p><p>")
                   .gsub(/\n+/, "</p><p>")
      content = "<p>" + content + "</p>"

      WebnovelDL::Model::Chapter.new(title, content, chapter_id)
        .tap { |c| after_chapter(c) }
    end

    def get_fiction(book_id : String) WebnovelDL::Model::Fiction
      fiction_url = MAIN_URL + "/#{book_id}"

      res = follow_redirect_and_get(fiction_url)
      raise "#{res.status_code}" unless res.status_code == 200
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes("//body//h1[@class='entry-title']")[0]
                 .text
                 .sub(/\s+[–\-]\s+Index/, "")
      author = ""

      fiction = WebnovelDL::Model::Fiction.new(
        title,
        author,
        Array(WebnovelDL::Model::Chapter).new
      )
      on_fiction(fiction)

      short_id = /(\w+)-index/.match(book_id).as(Regex::MatchData).captures.first

      chap_urls = xml.xpath_nodes("//body//div[@itemprop='articleBody']//a")
                     .map(&.attributes["href"].content)
                     .select { |c| c =~ /book|chapter|prologue|other-tales/ }

      chap_urls.each do |chap_url|
        /\/([a-z\-0-9]+)\/?$/.match(chap_url)
        fiction.chapters << get_chapter(book_id, $1)
      end

      fiction
    end

    private def follow_redirect_and_get(url, header = nil)
      @client.get(url, header) do |response|
        loop do
          case response.status_code
          when 200..299
            return response
          when 300..399
            new_url  = response.headers["Location"]
            response = @client.get(new_url, header)
          else
            exit 2
          end
        end
        response
      end
    end
  end
end
