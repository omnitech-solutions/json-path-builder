module JsonPath
  class DefaultDataWrapper < SimpleDelegator
    def initialize(data)
      super(data.deep_symbolize_keys)
    end
  end
end
