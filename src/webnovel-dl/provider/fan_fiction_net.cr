require "xml"

require "../model/*"

# NOTE: url is in the form:
#   https://www.fanfiction.net/s/{book_id}/{chapter_id}/{chapter_title}

module WebnovelDL
  class FanFictionNet < Provider
    MAIN_URL  = "https://www.fanfiction.net/s"

    def get_id_from_url(path : String) : String
      /s\/(\d+)/.match(path)
      $1
    end

    def get_chapter(fiction_id : String, chapter_id : String) : WebnovelDL::Model::Chapter
      chapter_url = MAIN_URL + "/#{fiction_id}/#{chapter_id}"

      res = @client.get(chapter_url)
      xml = XML.parse_html(res.body)

      content = xml.xpath_nodes("//body//div[@id='storytext']/p")
                   .map(&.text)
                   .join("</p><p>")
      content = "<p>" + content + "</p>"
      WebnovelDL::Model::Chapter.new(chapter_id, content, chapter_id).tap { |c| after_chapter(c) }
    end

    def get_fiction(fiction_id : String) : WebnovelDL::Model::Fiction
      fiction_url = MAIN_URL + "/#{fiction_id}"

      res = @client.get(fiction_url)
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes("//body//*[@id='profile_top']/b")[0].text
      author = xml.xpath_nodes("//body//*[@id='profile_top']/a")[0].text

      fiction = WebnovelDL::Model::Fiction.new(title, author, Array(WebnovelDL::Model::Chapter).new)
      on_fiction(fiction)

      # get the chapter_count from <select id='chap_select'...> number of <option>
      # divide the size by 2 because there are 2 sets of <select> top and bottom
      chap_count = xml.xpath_nodes("//body//select[@id='chap_select']/option").size / 2
      chap_count.times { |i| fiction.chapters << get_chapter(fiction_id, (i + 1).to_s) }

      return fiction
    end
  end
end
