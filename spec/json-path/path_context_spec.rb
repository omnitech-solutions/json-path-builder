module JsonPath
  RSpec.describe PathContext do
    let(:builder) { double("PathsBuilder", nested_paths: []) }
    let(:data) { { foo: "bar" } }
    let(:transform) { :iso8601 }
    let(:json_path) { "foo" }
    let(:defaults) { nil }
    let(:path_context) do
      described_class.new(json_path, builder, iterable_data: false, transform: transform, use_builder: false,
                                              defaults: defaults, fallback_proc: nil, skip_if_proc: nil)
    end

    describe "#initialize" do
      context "when json_path is blank" do
        let(:json_path) { '   ' }

        it "raises an ArgumentError" do
          expect { path_context }.to raise_error(ArgumentError, "`from` must be filled")
        end
      end

      context "when transform is not a symbol or a valid transform key" do
        let(:transform) { "not_a_symbol_or_valid_transform" }

        it "raises an ArgumentError" do
          expect do
            path_context
          end.to raise_error(ArgumentError,
                             "`transform`: 'not_a_symbol_or_valid_transform' must be one of [:iso8601, :date]")
        end
      end
    end

    describe "#parent" do
      context "when the builder has a parent_path_context" do
        let(:parent_path_context) { double("PathContext") }

        before { allow(builder).to receive(:parent_path_context).and_return(parent_path_context) }

        it "returns the parent_path_context" do
          expect(path_context.parent).to eq(parent_path_context)
        end
      end

      context "when the builder does not have a parent_path_context" do
        before { allow(builder).to receive(:parent_path_context).and_return(nil) }

        it "returns nil" do
          expect(path_context.parent).to be_nil
        end
      end
    end

    describe "#defaults?" do
      context "when defaults is an empty hash" do
        let(:defaults) { {} }

        it "returns false" do
          expect(path_context.defaults?).to be false
        end
      end

      context "when defaults is a non-empty hash" do
        let(:defaults) { { baz: "qux" } }

        it "returns true" do
          expect(path_context.defaults?).to be true
        end
      end
    end

    describe "#transformable?" do
      context "when transform is a Proc" do
        let(:transform) { ->(val) { val.to_s.upcase } }

        it "returns true" do
          expect(path_context.transformable?).to be true
        end
      end

      context "when transform is not a Proc" do
        let(:transform) { nil }

        it "returns false" do
          expect(path_context.transformable?).to be false
        end
      end
    end
  end
end
