require "xml"
require "uri"

require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class GravityTales < Provider
    MAIN_URL               = "https://gravitytales.com"
    CHAPTER_URL            = "https://gravitytales.com/Novel"
    JSON_NOVELS_URL        = "https://gravitytales.com/api/novels"
    JSON_CHAPTERGROUPS_URL = "https://gravitytales.com/api/novels/chaptergroups"
    JSON_CHAPTERGROUP_URL  = "https://gravitytales.com/api/novels/chaptergroup"

    def get_id_from_url(path : String) : String
      /\/([a-z\-]+)$/.match(path).as(Regex::MatchData).captures.first.as(String)
    end

    def get_chapter(book_id : String, chapter_id : String) WebnovelDL::Model::Chapter
      chap_url = CHAPTER_URL + "/#{book_id}/#{chapter_id}"

      res = follow_redirect_and_get(chap_url)
      xml = XML.parse_html(res.body)

      title = xml.xpath_nodes("//body//div//h4").first.text
      content = xml.xpath_nodes("//body//div[@id='chapterContent']/p").map do |p|
        p.text
      end.join("</p><p>").gsub(/\n+/, "</p><p>")
      content = "<p>" + content + "</p>"

      WebnovelDL::Model::Chapter.new(title, content, chapter_id)
        .tap { |c| after_chapter(c) }
    end

    def get_fiction(book_id : String) WebnovelDL::Model::Fiction
      fiction_url = MAIN_URL + "/novel/#{book_id}"

      res = follow_redirect_and_get(fiction_url)
      raise "Not 200" unless res.success?
      xml = XML.parse_html(res.body)

      # title = xml.xpath_nodes("//body//div//h3")[0].text.sub("(RSS)", "").strip
      title = xml.xpath_nodes("//head/title")[0]
                 .text
                 .sub("- Gravity Tales", "")
                 .strip
      author = xml.xpath_nodes(
        "//body//div//div[@class='desc']/p"
      ).select do |p|
        p.text =~ /Author:/
      end.first.text

      if /Title:|Status:/.match(author)
        author = /Author:(.+)Status/.match(author).as(Regex::MatchData)
                                    .captures
                                    .first.as(String)
                                    .strip
      else
        author = author.sub("Author:", "").strip
      end

      fiction = WebnovelDL::Model::Fiction.new(
        title,
        author,
        Array(WebnovelDL::Model::Chapter).new
      ).tap { |f| on_fiction(f) }

      # GET CHAPTER URLS

      # novel listing in json
      res = @client.get(JSON_NOVELS_URL)
      json = JSON.parse(res.body)

      # find the novel we're looking for
      fic = json.select { |j| j["Slug"] == book_id }.first

      # go to our novel's chaptergroups page to find the chaptergroup id's
      chaptergroups_url = "#{JSON_CHAPTERGROUPS_URL}/#{fic["Id"]}"
      res = @client.get(chaptergroups_url)
      json = JSON.parse(res.body)

      # get chaptergroup id's
      chap_urls_json = Array(JSON::Any).new
      json.each do |j|
        res = @client.get("https://gravitytales.com/api/novels/chaptergroup/#{j["ChapterGroupId"]}")
        chap_urls_json.concat(JSON.parse(res.body))
      end

      # get chapter slugs to which we can append to CHAPTER_URL
      chap_urls = chap_urls_json.map { |c| c["Slug"].to_s }

      # build fiction's chapters
      chap_urls.each do |chap_url|
        fiction.chapters << get_chapter(book_id, chap_url)
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
