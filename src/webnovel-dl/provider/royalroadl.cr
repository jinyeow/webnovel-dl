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

    def get_chapter(chapter_id : String) : WebnovelDL::Model::Chapter
      url = MAIN_URL + "/fiction/chapter/#{chapter_id}"
      res = follow_redirect_and_get(url)
      xml = XML.parse_html(res.body)

      content = xml.xpath_nodes("//body//*[contains(@class,
                                'chapter-content')]")[0].text
      content = "<p>#{content.gsub(/[\r\n]+/, "</p><p>")}</p>"
      title = xml.xpath_nodes("//body//div[contains(@class, 'col-md-5')]/h1")[0].text

      WebnovelDL::Model::Chapter.new(title, content, chapter_id)
    end

    def get_chapter(book_id : String, chapter_id : String) : WebnovelDL::Model::Chapter
      get_chapter(chapter_id).tap { |c| after_chapter(c) }
    end

    def get_fiction(id : String) : WebnovelDL::Model::Fiction
      url = MAIN_URL + "/fiction/#{id}"
      res = follow_redirect_and_get(url)
      xml = XML.parse_html(res.body)

      author = xml.xpath_node("//body//span[@property='name']").as(XML::Node).text
      title = xml.xpath_node("//body//h1[@property='name']").as(XML::Node).text.strip

      chapters = xml.xpath_nodes("//body//tbody/tr").map do |node|
        /chapter\/(\d+)/.match(node.attributes["data-url"].text)
        get_chapter(id, $1)
      end

      WebnovelDL::Model::Fiction.new(title, author, chapters).tap { |f| on_fiction(f) }
    end

    # TODO: refactor this out to scraper.cr or to a helper module, so other
    #   providers can use this as well.
    private def follow_redirect_and_get(url)
      @client.get(url) do |response|
        until response.status_code == 200
          case response.status_code
          when 200..299
            return response
          when 300..399
            body = response.body_io.gets_to_end.as(String)
            old_path = URI.parse(url).path.as(String)
            new_path = XML.parse_html(body).xpath_node("//body/h2/a")
                          .as(XML::Node)["href"]
            new_url = url.sub(old_path, new_path)
            response = @client.get(new_url)
          end
        end
        response
      end
    end
  end
end

# NOTE: This is the working out I did in crystal playground. Got the first part
#   of get_fiction() done.
#   The main problem was that the initial HTTP::Client.get(url) returns a 301 Moved.
#   We should setup a class HTTPClient that wraps the stdlib to handle
#   following redirects etc.
#   We can also setup a way to convert css to xpath queries OR we can just use the XPath
#   queries.
#   Look at 'https://github.com/madeindjs/Crystagiri' for CSS query conversion.
#   It's a good place to start.
#
# require "xml"
# rr_url = "https://royalroadl.com"
# #    let client = newHttpClient()
# #    let url = "http://royalroadl.com/fiction/$1".format(id)
# url = rr_url + "/fiction/3146"
# #    let xml = parseHtml(newStringStream(client.getContent(url)))
#
# NOTE: This part should go into class HTTPClient. Loop 'n' times to follow
#   redirects.
# res = client.get(url) do |response|
#   case response.status_code
#   when 200
#     response
#   when 301
#     NOTE: These variables had to be cast using #as(T) since they were all
#       union types of (T | Nil). Very irritating.
#     body = response.body_io.gets_to_end.as(String)
#     str = URI.parse(url).path.as(String)
#     new_path = XML.parse_html(body).xpath_node("//body/h2/a").as(XML::Node)["href"]
#     new_url = url.sub(str, new_path)
#     client.get(new_url)
#   end
# end
# 
# res = res.as(HTTP::Client::Response)
# res.body
# xml = XML.parse_html(res.as(HTTP::Client::Response).body)
# 
# #URI.parse(url).path
# author = xml.xpath_nodes("//body//span[@property='name']")[0].text
# #    let title  = xml.querySelector("h1[property='name']").innerText()
# title = xml.xpath_nodes("//body//h1[@property='name']")[0].text
