module OpenAI
  class Evals
    def initialize(client:)
      @client = client
    end

    def create(parameters: {})
      @client.json_post(path: "/evals", parameters: parameters)
    end

    def retrieve(id:)
      @client.get(path: "/evals/#{id}")
    end

    def update(id:, parameters: {})
      @client.json_post(path: "/evals/#{id}", parameters: parameters)
    end

    def delete(id:)
      @client.delete(path: "/evals/#{id}")
    end

    def list(parameters: {})
      @client.get(path: "/evals", parameters: parameters)
    end

    def runs
      @runs ||= Runs.new(client: @client)
    end

    class Runs
      def initialize(client:)
        @client = client
      end

      def create(eval_id:, parameters: {})
        @client.json_post(path: "/evals/#{eval_id}/runs", parameters: parameters)
      end

      def retrieve(eval_id:, id:)
        @client.get(path: "/evals/#{eval_id}/runs/#{id}")
      end

      def list(eval_id:, parameters: {})
        @client.get(path: "/evals/#{eval_id}/runs", parameters: parameters)
      end

      def cancel(eval_id:, id:)
        @client.post(path: "/evals/#{eval_id}/runs/#{id}/cancel")
      end

      def delete(eval_id:, id:)
        @client.delete(path: "/evals/#{eval_id}/runs/#{id}")
      end

      def output_items
        @output_items ||= OutputItems.new(client: @client)
      end

      class OutputItems
        def initialize(client:)
          @client = client
        end

        def list(eval_id:, run_id:, parameters: {})
          @client.get(path: "/evals/#{eval_id}/runs/#{run_id}/output_items", parameters: parameters)
        end

        def retrieve(eval_id:, run_id:, id:)
          @client.get(path: "/evals/#{eval_id}/runs/#{run_id}/output_items/#{id}")
        end
      end
    end
  end
end
