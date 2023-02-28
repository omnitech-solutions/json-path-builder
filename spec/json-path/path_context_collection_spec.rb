module JsonPath
  # rubocop:disable Layout/LineLength,RSpec/MessageSpies,RSpec/StubbedMock
  RSpec.describe PathContextCollection do
    describe '#reject_from_paths!' do
      let(:path_context1) { instance_double(PathContext, from: 'path1') }
      let(:path_context2) { instance_double(PathContext, from: 'path2') }
      let(:path_context3) { instance_double(PathContext, from: 'path3') }

      it 'removes elements from the collection with matching from paths' do
        collection = described_class.new([])
        collection.push(path_context1, path_context2, path_context3)

        collection.reject_from_paths!(%w[path1 path3])

        expect(collection).to include(path_context2)
        expect(collection).not_to include(path_context1, path_context3)
      end
    end

    describe '#add_path' do
      let(:paths_builder) { instance_double(Builder) }
      let(:iterable_data) { true }
      let(:transform) { proc { |data| data.upcase } }
      let(:defaults) { { foo: 'bar' } }
      let(:fallback_proc) { proc { 'fallback' } }
      let(:skip_if_proc) { proc { |data| data.nil? } }
      let(:path_context) { instance_double(PathContext) }

      before do
        allow(PathContext).to receive(:new).and_return(path_context)
      end

      it 'adds a new PathContext object to the collection' do
        collection = described_class.new([])
        expect(PathContext).to receive(:new).with('path', paths_builder, to: nil, iterable_data: iterable_data,
                                                                         transform: transform, use_builder: true, defaults: defaults, fallback_proc: fallback_proc, skip_if_proc: skip_if_proc).and_return(path_context)

        result = collection.add_path('path', paths_builder, iterable_data: iterable_data, transform: transform,
                                                            defaults: defaults, fallback_proc: fallback_proc, skip_if_proc: skip_if_proc)

        expect(result).to include(path_context)
      end
    end
  end
  # rubocop:enable Layout/LineLength,RSpec/MessageSpies,RSpec/StubbedMock
end
