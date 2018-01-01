require "spec"
require "../src/webnovel-dl"

def create_chapter(title : String, content : String, id : String)
  WebnovelDL::Model::Chapter.new(title, content, id)
end

def create_fiction(title : String, author : String, chapters :
                   Array(WebnovelDL::Model::Chapter))
end
