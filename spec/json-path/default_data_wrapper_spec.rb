module JsonPath
  RSpec.describe DefaultDataWrapper do
    describe '#[]' do
      context 'when the wrapped object is a hash with string keys' do
        let(:data) { { 'name' => 'John', 'age' => 30 } }
        let(:wrapper) { described_class.new(data) }

        it 'returns the value associated with the symbol key' do
          expect(wrapper[:name]).to eq('John')
          expect(wrapper[:age]).to eq(30)
        end

        it 'does not modify the original hash' do
          expect { wrapper[:name] }.not_to(change { data })
        end
      end

      context 'when the wrapped object is a hash with symbol keys' do
        let(:data) { { name: 'John', age: 30 } }
        let(:wrapper) { described_class.new(data) }

        it 'returns the value associated with the symbol key' do
          expect(wrapper[:name]).to eq('John')
          expect(wrapper[:age]).to eq(30)
        end

        it 'does not modify the original hash' do
          expect { wrapper[:name] }.not_to(change { data })
        end
      end
    end
  end
end
