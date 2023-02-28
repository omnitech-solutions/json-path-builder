# JsonPathBuilder

Aims to provide a declarative JSON based mapper

## Console
run `irb -r ./dev/setup` for an interactive prompt.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json-path-builder'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install json-path-builder

## JsonPath::Builder

### .build_for
> maps input based fields to be mapped via `.from` method

For advance usage check out `.from` documentation

```ruby
input = { key: "some-value" }
JsonPath::Builder.new.from(:key, to: :another_key).build_for(input) 
#=> {:another_key=>"some-value"}
```

### .from
> defines the json path(s) to locate the value(s) to be mapped for each field

#### Required arguments:
 - `json_path` ~ JSON path supporting dot notation which contains the value(s) relating to the field to be mapped e.g. `account.profile.name` 

#### Optional arguments:
- `to:` ~ field name for mapped value (defaults to `json_path`)
- `transform:`
  - can be one of the following
    - `Proc` e.g. `->(val) { val.to_s.upcase }` to convert value located at `json_path` to uppercase
    - Built in Transforms
      - `:iso8601` e.g. `Date.new(2022,1,1)` => `2022-01-01`
      - `:date` e.g. `2022-01-01` => `<Date Sat, 01 Jan 2022>`
  - `defaults` - (Hash) e.g. `{user_id: 1}`
  - `fallback` - (Proc) used when mapped value is `blank`

Example:

```ruby
# Example 1 - Mapping subset of fields
input = { key: "some-value", other_key: "some-other-value", list: %w[some-list-value-1 some-list-value-2] }.as_json
builder = JsonPath::Builder.new
builder.from(:key)
builder.from(:other_key)
builder.build_for(input) #=> {:key=>"some-value", :other_key=>"some-other-value"}

# Example 2 - Mapping nested field to non nested
input = { profile: {email: 'email@domain.com'} }.as_json
JsonPath::Builder.new.from('profile.email', to: :email).build_for(input) #=> {:email=>"email@domain.com"}

# Example 3 - mapping field to another field name
input = { key: "some-value" }
JsonPath::Builder.new.from(:key, to: :another_key).build_for(input) #=> {:another_key=>"some-value"}

# Example 4 - mapping field to nested field
input = { key: "some-value" }
JsonPath::Builder.new.from(:key, to: "root.key").build_for(input) #=> {:root=>{:key=>"some-value"}}

# Example 5 - transforming value to uppercase
input = { key: "some-value" }
transform = ->(val) { val.to_s.upcase }
JsonPath::Builder.new.from(:key, transform: transform).build_for(input) #=> {:key=>"SOME-VALUE"}

# Example 6 - transforming value to iso8601 format
input = { created_at: Date.new(2022,1,2) }
transform = :iso8601
JsonPath::Builder.new.from(:created_at, transform: transform).build_for(input) #=> {:created_at=>"2022-01-02"}

# Example 6 - transforming value to iso8601 format
input = { created_at: '2023-02-27 16:24:02' }
transform = :date
JsonPath::Builder.new.from(:created_at, transform: transform).build_for(input) #=> {:created_at=><Date Sat, 01 Jan 2022>}

# Example 7 - fallback when value to be mapped is `nil` or not present
input = { }
fallback = -> { Time.now }
JsonPath::Builder.new.from(:created_at, fallback: fallback).build_for(input)
# => {:created_at=> <Time 2023-02-27 16:36:44.068037 -0700>}
```

### .from_each
> similar to `.from` but for mapping list items

Example:

```ruby
input = { list: %w[some-list-value-1 some-list-value-2] }.as_json
builder = JsonPath::Builder.new
transform = proc { |val| val.upcase }
builder.from_each(:list, to: :keys, transform: transform)
builder.build_for(input) #=> {:keys=>["SOME-LIST-VALUE-1", "SOME-LIST-VALUE-2"]}
```

### .within
> Adds the ability to provide a scope based on dot notation

Example:

```ruby
input = { root: { deep: { profile: { email: 'email@domain.com', uid: 1 } } } }.as_json
builder = JsonPath::Builder.new
builder.within('root.deep.profile') do |b|
  b.from(:email)
  b.from(:uid, to: :user_id)
end

builder.build_for(input) #=> {:email=>"email@domain.com", :user_id=>1}
```

### #with_wrapped_data_class
> Supports wrapping mapped values with a custom class that must act like a hash i.e. implements `SimpleDelegator`

Example:

```ruby
input = { profile: { email: 'email@domain.com', uid: 1 } }.as_json
builder = JsonPath::Builder.new
wrapped_data_class = Class.new(SimpleDelegator) do
  def user
    User.find_by(email: self[:email])
  end
end
builder.with_wrapped_data_class(wrapped_data_class)
transform = proc { |email, path_context| }
builder.from('profile.email', to: :user_id, transform: transform)


email = 'email@domain.com'
user_id = 123
input = { profile: { email: email } }.as_json
user = OpenStruct.new(id: user_id)
user_repo = OpenStruct.new(find_by: -> (_email) { user })

wrapped_data_class = Class.new(SimpleDelegator) do
  class << self
    attr_accessor :user_repo
  end

  def user
    self.class.user_repo.find_by.call(email: self.dig('profile', 'email'))
  end
end
wrapped_data_class.user_repo = user_repo

builder = JsonPath::Builder.new
builder.with_wrapped_data_class(wrapped_data_class)
transform = proc do |_email, path_context|
  path_context.wrapped_source_data.user.id
end

builder.from('profile.email', to: :user_id, transform: transform)
builder.build_for(input) #=> {:user_id=>123}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/json-path-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/json-path-builder/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonPathBuilder project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/json-path-builder/blob/master/CODE_OF_CONDUCT.md).
