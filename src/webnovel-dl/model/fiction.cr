require "./chapter"

module WebnovelDL
  module Model
    class Fiction
      property :title, :author, :chapters

      def initialize(@title : String, @author : String, @chapters :
                     Array(WebnovelDL::Model::Chapter))
      end
    end
  end
end
