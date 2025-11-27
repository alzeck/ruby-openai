RSpec.describe OpenAI::Client do
  describe "#evals" do
    let(:eval_params) do
      {
        name: "Sentiment Analysis",
        data_source_config: {
          type: "custom",
          item_schema: {
            type: "object",
            properties: {
              input: { type: "string" }
            },
            required: ["input"]
          },
          include_sample_schema: true
        },
        testing_criteria: [
          {
            type: "label_model",
            model: "o3-mini",
            input: [
              { role: "developer",
                content: "Classify the sentiment of the following statement " \
                         "as one of 'positive', 'neutral', or 'negative'" },
              { role: "user", content: "Statement: {{item.input}}" }
            ],
            passing_labels: ["positive"],
            labels: %w[positive neutral negative],
            name: "Sentiment grader"
          }
        ]
      }
    end
    let(:eval_id) do
      VCR.use_cassette("#{cassette} setup") do
        OpenAI::Client.new.evals.create(
          parameters: eval_params
        )["id"]
      end
    end

    let(:run_params) do
      {
        name: "Run 1",
        data_source: {
          type: "completions",
          input_messages: {
            type: "template",
            template: [
              {
                role: "developer",
                content: "You are a helpful assistant."
              },
              {
                role: "user",
                content: "{{item.input}}"
              }
            ]
          },
          model: "gpt-4o-mini",
          source: {
            type: "file_content",
            content: [
              {
                item: {
                  input: "I love this product!",
                  ground_truth: "positive"
                }
              }
            ]
          }
        }
      }
    end

    let(:run_id) do
      VCR.use_cassette("#{cassette} run setup") do
        OpenAI::Client.new.evals.runs.create(
          eval_id: eval_id,
          parameters: run_params
        )["id"]
      end
    end

    describe "#retrieve" do
      let(:cassette) { "evals retrieve" }
      let(:response) { OpenAI::Client.new.evals.retrieve(id: eval_id) }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("eval")
          expect(response["id"]).to eq(eval_id)
        end
      end
    end

    describe "#create" do
      let(:cassette) { "evals create" }
      let(:response) do
        OpenAI::Client.new.evals.create(
          parameters: eval_params
        )
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("eval")
          expect(response["name"]).to eq("Sentiment Analysis")
        end
      end
    end

    describe "#update" do
      let(:cassette) { "evals update" }
      let(:response) do
        OpenAI::Client.new.evals.update(
          id: eval_id,
          parameters: { metadata: { modified: "true" } }
        )
      end

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("eval")
        end
      end
    end
    describe "#list", :vcr do
      let(:cassette) { "evals list" }
      let(:response) { OpenAI::Client.new.evals.list }

      before { eval_id }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("list")
          expect(response["data"]).to be_an(Array)
          expect(response.dig("data", 0, "object")).to eq("eval") if response["data"].any?
        end
      end
    end

    describe "#runs" do
      describe "#retrieve" do
        let(:cassette) { "evals runs retrieve" }
        let(:response) do
          OpenAI::Client.new.evals.runs.retrieve(
            eval_id: eval_id,
            id: run_id
          )
        end

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["object"]).to eq("eval.run")
            expect(response["id"]).to eq(run_id)
            expect(response["eval_id"]).to eq(eval_id)
          end
        end
      end

      describe "#create" do
        let(:cassette) { "evals runs create" }
        let(:response) do
          OpenAI::Client.new.evals.runs.create(
            eval_id: eval_id,
            parameters: run_params
          )
        end

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["object"]).to eq("eval.run")
            expect(response["eval_id"]).to eq(eval_id)
            expect(response["name"]).to eq("Run 1")
          end
        end
      end

      describe "#output_items" do
        describe "#list", :vcr do
          let(:cassette) { "evals runs output_items list" }
          let(:response) do
            OpenAI::Client.new.evals.runs.output_items.list(
              eval_id: eval_id,
              run_id: run_id
            )
          end

          it "succeeds" do
            VCR.use_cassette(cassette) do
              expect(response["object"]).to eq("list")
              expect(response["data"]).to be_an(Array)
            end
          end
        end

        describe "#retrieve" do
          let(:cassette) { "evals runs output_items retrieve" }
          let(:output_item_id) do
            OpenAI::Client.new.evals.runs.output_items.list(
              eval_id: eval_id,
              run_id: run_id
            )["data"].first["id"]
          end
          let(:response) do
            OpenAI::Client.new.evals.runs.output_items.retrieve(
              eval_id: eval_id,
              run_id: run_id,
              id: output_item_id
            )
          end

          it "succeeds" do
            VCR.use_cassette(cassette) do
              expect(response["object"]).to eq("eval.run.output_item")
              expect(response["id"]).to eq(output_item_id)
            end
          end
        end
      end

      describe "#cancel" do
        let(:cassette) { "evals runs cancel" }
        let(:response) do
          OpenAI::Client.new.evals.runs.cancel(
            eval_id: eval_id,
            id: run_id
          )
        end

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["object"]).to eq("eval.run")
            expect(response["status"]).to eq("canceled")
          end
        end
      end

      describe "#delete" do
        let(:cassette) { "evals runs delete" }
        let(:response) do
          OpenAI::Client.new.evals.runs.cancel(
            eval_id: eval_id,
            id: run_id
          )

          OpenAI::Client.new.evals.runs.delete(
            eval_id: eval_id,
            id: run_id
          )
        end

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["object"]).to eq("eval.run.deleted")
          end
        end
      end
    end

    describe "#delete" do
      let(:cassette) { "evals delete" }
      let(:response) do
        OpenAI::Client.new.evals.delete(id: eval_id)
      end
      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["object"]).to eq("eval.deleted")
        end
      end
    end
  end
end
