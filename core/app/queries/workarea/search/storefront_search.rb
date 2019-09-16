module Workarea
  module Search
    class StorefrontSearch
      attr_reader :params

      def initialize(params)
        @params = params
        @used_middleware = []
      end

      def customization
        return @customization if defined?(@customization)

        result = Customization.find_by_query(params[:q].try(:strip).to_s)
        @customization = result.active? ? result : nil
      end

      def response
        @response ||=
          begin
            result = StorefrontSearch::Response.new(
              params: params,
              customization: customization
            )
            chain = create_middleware_chain

            traverse_chain = lambda do
              unless chain.empty?
                piece = chain.shift
                @used_middleware << piece
                piece.call(result, &traverse_chain)
              end
            end

            traverse_chain.call
            result
          end
      end

      def used_middleware
        response
        @used_middleware
      end

      def create_middleware_chain
        Workarea.config.storefront_search_middleware.map do |class_name|
          class_name.constantize.new(params, customization)
        end
      end
    end
  end
end
