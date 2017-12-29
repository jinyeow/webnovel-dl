module WebnovelDL
  module Model
    class Chapter
      property :title, :content, :id

      def initialize(@title : String, @content : String, @id : String)
      end
    end
  end
end
