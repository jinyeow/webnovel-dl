require "http"
require "xml"

require "../provider.cr"
require "../model/chapter"
require "../model/fiction"

module WebnovelDL
  class RoyalRoadL < Provider
    MAIN_URL = "http://royalroadl.com"

    def initialize(@client : HTTP::Client = HTTP::Client)
    end

    def get_chapter(id : String) : WebnovelDL::Model::Chapter
    end

    def get_fiction(id : String) : WebnovelDL::Model::Fiction
      url = MAIN_URL + "/fiction/#{id}"
      xml = @client.get(url).body
      document = XML.parse_html(xml)

      author = xml.
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
