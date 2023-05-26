module JsonPath
  # rubocop:disable Metrics/ParameterLists
  class PathContextCollection < SimpleDelegator
    ROOT_PATHS = %w[* .].freeze

    attr_reader :source_data, :builder

    def initialize(paths_builder)
      @builder = paths_builder
      @source_data = nil
      @nested_paths = []

      super([])
    end

    def reject_from_paths!(from_paths)
      reject! { |path_context| from_paths.include?(path_context.from.to_s) }
    end

    def data_wrapper_class
      @data_wrapper_class || DefaultDataWrapper
    end

    def nested_paths
      @nested_paths.reject { |p| p.blank? || ROOT_PATHS.include?(p) }
    end

    def within(json_path)
      @nested_paths.push(json_path)
      yield builder
      @nested_paths.pop
    end

    def add_path(path, paths_builder,
                 iterable_data:,
                 transform:,
                 defaults:,
                 fallback_proc:,
                 skip_if_proc:,
                 to: nil,
                 use_builder: true)
      push(PathContext.new(path, paths_builder,
                           to: to,
                           iterable_data: iterable_data,
                           transform: transform,
                           use_builder: use_builder,
                           defaults: defaults,
                           fallback_proc: fallback_proc,
                           skip_if_proc: skip_if_proc))
      self
    end

    def with_source_data(data)
      @source_data = data

      each { |path| path.with_source_data(data) }
      self
    end

    def with_wrapped_data_class(klass)
      @data_wrapper_class = klass
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
