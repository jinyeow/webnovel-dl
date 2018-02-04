require "spec"
require "../src/webnovel-dl/*"

def some_chapter
  WebnovelDL::Model::Chapter.new(
    "Test Title",
    "<p>some content goes here</p>",
    "1234"
  )
end

def epub
  some_fiction = WebnovelDL::Model::Fiction.new(
    "Fiction Title",
    "Fiction Author",
    [some_chapter]
  )

  some_chapter.should be_a WebnovelDL::Model::Chapter
  some_fiction.should be_a WebnovelDL::Model::Fiction

  WebnovelDL::Epub.new(some_fiction)
end
