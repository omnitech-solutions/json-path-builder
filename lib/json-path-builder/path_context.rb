module JsonPath
  # rubocop:disable Metrics/ParameterLists,Metrics/PerceivedComplexity
  class PathContext
    COMMON_TRANSFORMS = {
      iso8601: ->(val) { val.is_a?(Date) ? val.iso8601 : val },
      date: lambda do |val|
        val.is_a?(String) ? (defined? Time.zone.parse) && Time.zone.parse(val)&.to_date : val
      rescue ArgumentError
        val
      end
    }.freeze

    attr_reader :from, :to, :transform, :use_builder, :defaults, :fallback_proc, :skip_if_proc, :builder, :data,
                :source_data, :nested_paths, :nested_data, :mapped_data

    delegate :data_wrapper_class, to: :builder

    # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    def initialize(json_path, paths_builder, iterable_data:, transform:, use_builder:, defaults:, fallback_proc:,
                   to: nil, skip_if_proc: nil)
      allowed_transform_types = COMMON_TRANSFORMS.keys

      raise ArgumentError, '`from` must be filled' if json_path.blank?

      if (transform.is_a?(Symbol) || transform.is_a?(String)) && COMMON_TRANSFORMS.keys.exclude?(transform.to_sym)
        raise ArgumentError,
              "`transform`: '#{transform}' must be one of #{allowed_transform_types.inspect}"
      end

      @builder = paths_builder
      @from = json_path.is_a?(Array) ? json_path.map(&:to_s) : json_path.to_s
      @iterable_data = iterable_data
      @nested_paths = paths_builder.nested_paths.dup.freeze
      @to = to.present? ? to : json_path.to_s
      @transform = transform.is_a?(Symbol) ? COMMON_TRANSFORMS[transform] : transform
      @use_builder = use_builder
      @defaults = Rordash::HashUtil.deep_symbolize_keys(defaults || {})
      @fallback_proc = fallback_proc
      @skip_if_proc = skip_if_proc || proc { false }

      @skip = false
      @nested_data = nil
    end
    # rubocop:enable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize

    def parent
      builder.parent_path_context
    end

    def wrapped_source_data
      return nil if source_data.nil?

      @wrapped_source_data ||= data_wrapper_class.new(source_data)
    end

    def iterable_data?
      @iterable_data
    end

    def skippable?
      skip_if_proc.is_a?(Proc)
    end

    def fallback?
      fallback_proc.is_a?(Proc)
    end

    def nested?
      @nested_paths.present?
    end

    def defaults?
      @defaults.is_a?(Hash) && @defaults.present?
    end

    def transform_with_builder?
      !!@use_builder
    end

    def transformable?
      transform.is_a?(Proc)
    end

    def unmatched_nested?
      nested? && nested_data.blank?
    end

    def nested_data?
      @nested_data.present?
    end

    def with_source_data(data)
      @source_data = data.dup.freeze
      set_nested_data
      set_data

      self
    end

    def with_prev_mapped_data(data)
      @mapped_data = data.dup.freeze
    end

    def to_h
      {
        from: from,
        to: to,
        data: data,
        source_data: source_data,
        nested_data: nested_data,
        mapped_data: mapped_data,
        transform: transform,
        use_builder: use_builder,
        defaults: defaults,
        fallback_proc: fallback_proc,
        skip_if_proc: skip_if_proc
      }
    end

    private

    def set_nested_data
      return if @nested_paths.empty?

      @nested_data = Rordash::HashUtil.get(source_data, @nested_paths.join('.'))
    end

    def set_data
      @data = nested_data? ? nested_data.dup : source_data.dup

      self
    end
  end
  # rubocop:enable Metrics/ParameterLists,Metrics/PerceivedComplexity
end
