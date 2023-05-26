module JsonPath
  # rubocop:disable Metrics/ClassLength
  class Builder
    attr_reader :path_context_collection, :parent_path_context

    delegate :source_data, :nested_paths, :data_wrapper_class, :reject_from_paths!, to: :path_context_collection,
             allow_nil: true

    def initialize(parent_path_context: nil)
      @parent_path_context = parent_path_context
      @path_context_collection = PathContextCollection.new(self)
    end

    def within(json_path, &block)
      path_context_collection.within(json_path, &block)

      self
    end

    def with_wrapped_data_class(klass)
      path_context_collection.with_wrapped_data_class(klass)

      self
    end

    # rubocop:disable Metrics/ParameterLists
    def from(json_path, to: nil, transform: nil, defaults: nil, fallback: nil, transform_with_builder: false)
      @path_context_collection.add_path(json_path, self,
                                        iterable_data: false,
                                        to: to,
                                        transform: transform,
                                        use_builder: transform_with_builder,
                                        defaults: defaults,
                                        fallback_proc: fallback,
                                        skip_if_proc: nil)

      self
    end

    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/ParameterLists
    def from_each(json_path, to: nil, transform: nil, skip_if: nil, defaults: nil, fallback: nil,
                  transform_with_builder: false)
      @path_context_collection.add_path(json_path, self,
                                        to: to,
                                        iterable_data: true,
                                        transform: transform,
                                        use_builder: transform_with_builder,
                                        defaults: defaults,
                                        fallback_proc: fallback,
                                        skip_if_proc: skip_if)

      self
    end

    # rubocop:enable Metrics/ParameterLists

    def with_source_data(data)
      path_context_collection.with_source_data(data)

      self
    end

    def without_from_paths!(from_paths_to_remove)
      path_context_collection.reject_from_paths!(from_paths_to_remove)

      self
    end

    def build
      raise 'source data must be filled' if source_data.nil?

      build_for(source_data)
    end

    def build_for(data, &each_value_block)
      path_contexts = with_source_data(data).path_context_collection
      self.class.build_for(path_contexts, &each_value_block)
    end

    def paths?
      @path_context_collection.count.positive?
    end

    class << self
      def build_for(path_contexts, &each_value_block)
        mapped_data = {}
        identity_proc = proc { |val| val }
        each_value_block = identity_proc unless each_value_block.is_a?(Proc)

        path_contexts.each do |path_context|
          path_context.with_prev_mapped_data(mapped_data)

          if path_context.unmatched_nested?
            set_mapped_value(mapped_data, key: path_context.to, value: get_fallback_value(path_context))
            next path_context
          end

          picked_value = value_at(path_context)
          transformed_value = get_transformed_value(picked_value, path_context)
          transformed_value = each_value_block.call(transformed_value, path_context)

          set_mapped_value(mapped_data, key: path_context.to, value: transformed_value)
        end
        mapped_data
      end

      private

      def set_mapped_value(mapped_data, key:, value:)
        Rordash::HashUtil.set(mapped_data, key.to_s, value)
      end

      def get_transformed_value(picked_value, path_context)
        return get_transformed_values(picked_value, path_context) if path_context.iterable_data?

        transformed_value = transform_value(picked_value, path_context)
        return transformed_value unless transformed_value.nil?

        get_fallback_value(path_context)
      end

      def get_fallback_value(path_context)
        return nil unless path_context.fallback?

        call_proc(path_context.fallback_proc, path_context)
      end

      def get_transformed_values(value, path_context)
        value = (value || [])
        value = value.reject { |val| path_context.skip_if_proc.call(val) } if path_context.skippable?
        Rordash::HashUtil.deep_symbolize_keys(value).each_with_index.map do |item|
          transform_value(item, path_context)
        end
      end

      def transform_value(value, path_context)
        return transform_value_with_builder(value, path_context) if path_context.transform_with_builder?
        return call_proc(path_context.transform, value, path_context) if path_context.transformable?

        value
      end

      def transform_value_with_builder(value, path_context)
        builder = Builder.new(parent_path_context: path_context)
        pb = call_proc(path_context.transform, builder, path_context)
        return pb.build_for(value) if pb&.paths?

        value
      end

      # rubocop:disable Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
      def value_at(path_context)
        from = path_context.from
        data = path_context.data

        val = if %w[* .].include?(from)
                data
              elsif from.is_a?(Array)
                Rordash::HashUtil.pick(data, from)
              elsif from.to_sym == :wrapped_source_data
                return path_context.wrapped_source_data
              else
                Rordash::HashUtil.get(data, from)
              end

        value = if path_context.iterable_data?
                  val = [val] unless val.is_a?(Array)
                  (val || []).map { |item| apply_defaults(item, path_context) }
                else
                  apply_defaults(val, path_context)
                end

        Rordash::HashUtil.deep_symbolize_keys(value)
      end

      # rubocop:enable Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity

      def apply_defaults(data, path_context)
        return data unless data.is_a?(Hash) && path_context.defaults?

        path_context.defaults.merge(data)
      end

      def exec_transform(value, path_context)
        return value unless path_context.transformable?

        call_proc(path_context.transform, value, path_context)
      end

      # rubocop:disable Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
      def call_proc(proc, *args, **extra_args)
        return nil unless proc.is_a?(Proc)

        allowed_proc_args = %i[req opt]
        proc_args_count = proc.parameters.count { |type, _| allowed_proc_args.include?(type) }

        allowed_kw_args = %i[key keyreq]
        proc_kw_args = proc.parameters.select { |type, _| allowed_kw_args.include?(type) }.map(&:second)

        without_extra_args = proc_args_count.zero? && proc_kw_args && args.present? && args.first.is_a?(Hash)
        extra_args = without_extra_args ? args.first : extra_args

        missing_args_count = [proc_args_count - args.count, 0].max

        found_args = proc_args_count.positive? ? args.take(proc_args_count) : []
        filled_args = found_args.present? ? found_args.fill(nil, found_args.count...missing_args_count + 1) : []
        filled_extra_args = extra_args.slice(*proc_kw_args)

        if proc_kw_args.present?
          call_proc_with_extra_args(proc, filled_args, filled_extra_args)
        else
          filled_args.present? ? proc.call(*filled_args) : proc.call
        end
      end

      # rubocop:enable Metrics/PerceivedComplexity,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize

      def call_proc_with_extra_args(proc, args, **extra_args)
        if args.present?
          args.first.is_a?(Hash) ? proc.call(**args.first) : proc.call

          proc.call(*args, **extra_args)
        else
          proc.call(**extra_args)
        end
      end
    end

    def keys
      path_context_collection.map(&:to)
    end
  end

  # rubocop:enable Metrics/ClassLength
end
