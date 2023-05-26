module JsonPath
  RSpec.describe Builder do
    let(:key) { "some-value" }
    let(:other_key) { "some-other-value" }
    let(:list) { %w[some-list-value-1 some-list-value-2] }

    let(:input) { { key: key, other_key: other_key, list: list }.as_json }

    subject(:instance) { described_class.new }

    describe '.from' do
      it 'handles simple path mapping' do
        %i[key other_key].each { |k| instance.from(k) }

        expect(instance.build_for(input)).to eql({ key: key, other_key: other_key })
      end

      it 'handles renaming path name' do
        instance.from(:other_key, to: :another_key)

        expect(instance.build_for(input)).to eql({ another_key: other_key })
      end

      it 'handles transformations' do
        instance.from(:key, transform: proc { |v| v.upcase })

        expect(instance.build_for(input)).to eql({ key: key.upcase })
      end
    end

    describe '.from_each' do
      it 'handles simple path mapping' do
        instance.from_each(:list)

        expect(instance.build_for(input)).to eql({ list: list })
      end

      context 'with complex mapping input' do
        let(:input) { { data: [{ name: 'some-name', region_code: 'AB' }] } }

        it 'supports building on list attributes' do
          instance.from_each(:data, transform_with_builder: true, transform: proc {|b|
            b.from(:name)
            b.from(:region_code, to: :state)
          })

          expect(instance.build_for(input)).to eql({ data: [{ name: 'some-name', state: 'AB' }] })
        end
      end

      it 'handles complex mapping via builder' do
        instance.from_each(:list)

        expect(instance.build_for(input)).to eql({ list: list })
      end

      it 'handles renaming path name' do
        instance.from(:list, to: :another_list_key)

        expect(instance.build_for(input)).to eql({ another_list_key: list })
      end

      it 'handles transformations' do
        instance.from_each(:list, transform: proc { |v| v.upcase })

        expect(instance.build_for(input)).to eql({ list: list.map(&:upcase) })
      end

      it 'handles skipping items' do
        instance.from_each(:list, skip_if: proc { |v| v == 'some-list-value-1' })

        expect(instance.build_for(input)).to eql({ list: ['some-list-value-2'] })
      end
    end

    describe '#within' do
      let(:email) { 'email@domain.com' }
      let(:user_id) { 1 }
      let(:input) { { root: { deep: { profile: { email: email, uid: user_id } } } }.as_json }

      it 'uses scope to simplify dot notation' do
        builder = described_class.new
        builder.within('root.deep.profile') do |b|
          b.from(:email)
          b.from(:uid, to: :user_id)
        end

        expect(builder.build_for(input)).to eql({ email: email, user_id: user_id })
      end
    end

    describe '#with_wrapped_data_class' do
      let(:email) { 'email@domain.com' }
      let(:user_id) { 123 }
      let(:input) { { profile: { email: email } }.as_json }
      let(:user) { double(:user, id: user_id) }
      let(:user_repo) { double(:user_repo, find_by: user) }

      let(:wrapped_data_class) do
        Class.new(SimpleDelegator) do
          class << self
            attr_accessor :user_repo
          end

          def user
            self.class.user_repo.find_by(email: dig('profile', 'email'))
          end
        end
      end

      before do
        wrapped_data_class.user_repo = user_repo
      end

      it 'wraps input data in wrapped class' do
        builder = described_class.new
        builder.with_wrapped_data_class(wrapped_data_class)
        transform = proc do |_email, path_context|
          path_context.wrapped_source_data.user.id
        end

        builder.from('profile.email', to: :user_id, transform: transform)
        expect(builder.build_for(input)).to eql({ user_id: user_id })
      end
    end

    describe '#wrapped_data_class' do
      context 'with custom data class' do
        let(:wrapper_class) { Class.new(DefaultDataWrapper) }

        it 'returns custom class' do
          instance.with_wrapped_data_class(wrapper_class)

          expect(instance.data_wrapper_class).to eql(wrapper_class)
        end
      end

      context 'without custom data class' do
        let(:custom_wrapper) { nil }

        it 'returns default class' do
          expect(instance.data_wrapper_class).to eql(DefaultDataWrapper)
        end
      end
    end
  end
end
