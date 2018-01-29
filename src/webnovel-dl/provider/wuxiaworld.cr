require "xml"
require "uri"

require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class WuxiaWorld < Provider
    MAIN_URL = "https://www.wuxiaworld.com"

    def get_id_from_url(path : String) : String
      path
    end

    def get_chapter(book_id : String, chapter_id : String) : Chapter
      chap_url = MAIN_URL + "/#{book_id}/#{chapter_id}"

      res = get_and_follow(chap_url)
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

      Chapter.new(title, content, chapter_id)
        .tap { |c| after_chapter(c) }
    end

    def get_fiction(book_id : String) Fiction
      fiction_url = MAIN_URL + "/#{book_id}"

      res = get_and_follow(fiction_url)
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes("//body//h1[@class='entry-title']")[0]
                 .text
                 .sub(/\s+[–\-]\s+Index/, "")
      begin
        author = xml.xpath_nodes("//body//div[@itemprop='articleBody']/p")
                    .select { |p| p.text =~ /Author/ }
                    .first
                    .text
        author = /Author:?(.+)$/.match(author).as(Regex::MatchData)
                    .captures
                    .first.as(String)
                    .strip("  ").strip # removes the weird 194_u8 whitespace
                                       # character as well as other whitespace
      rescue
        author = ""
      end

      fiction = Fiction.new(
        title,
        author,
        Array(Chapter).new
      )
      on_fiction(fiction)

      # short_id = /(\w+)-index/.match(book_id).as(Regex::MatchData).captures.first

      chap_urls = xml.xpath_nodes("//body//div[@itemprop='articleBody']//a")
                     .map(&.attributes["href"].content)
                     .select do |c|
                        URI.parse(c).host =~ /wuxiaworld/ && \
                          URI.parse(c).path =~ /book|chapter|prologue|other-tales/
                     end

      chap_urls.each do |chap_url|
        /\/([a-z\-0-9]+)\/?$/.match(chap_url)
        chap = get_chapter(book_id, $1)
        (chap.content.split("</p><p>").size > 5 ? fiction.chapters << chap : break)
      end

      fiction
    end
  end
end
