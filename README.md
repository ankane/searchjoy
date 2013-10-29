# Intel

[not ready for prime time]

Search analytics made easy

- track searches and conversions
- watch searches in real-time
- view searches with low conversions

## Get Started

Add this line to your application’s Gemfile:

```ruby
gem "intel"
```

Create a table to keep track of searches.

```sh
rails generate intel:install
rake db:migrate
```

Use the `track` option to track searches.

```ruby
Item.search "apple", track: true
```

Want to track more attributes? Use migrations to add them to the `searches` table. Then, pass the values to the `track` option.

```ruby
Item.search "apple", track: {user_id: 1, source: "web"}
```

It’s that easy!

Query the searches with:

```ruby
Intel::Search.all
```

## Track Conversions

Tracking search conversions is super important.  Intel makes this easy!

```ruby
@items = Item.search "apple", track: true
@items.search # returns search object
```

Add an end point to track conversions to your `config/routes.rb`.

```ruby
mount Intel::Conversions, at: "intel/conversions"
```

There are a few ways to hit this end point.

```ruby
intel.conversions_path(search_id: @items.search.id, convertable_id: 1, position: 3)
```

## View the Data

Add the dashboards to your `config/routes.rb`.

```ruby
mount Intel::Engine, at: "admin/intel"
```

Be sure to protect the endpoint in production.

#### Basic Authentication

Set the following variables in your environment or an initializer.

```ruby
ENV["INTEL_USERNAME"] = "andrew"
ENV["INTEL_PASSWORD"] = "secret"
```

#### Devise

```ruby
authenticate :user, lambda{|user| user.admin? } do
  mount Intel::Engine, at: "admin/intel"
end
```

## Customize

#### Live Stream

What is “Item 123”? Add the `intel_name` method in your model.

```ruby
def intel_name
  title # use the title method
end
```

#### Time Zone [coming soon]

By default, Intel use `Time.zone`. To set a specific zone, create an initializer `config/initializers/intel.rb` with:

```ruby
Intel.default_time_zone = "Pacific Time (US & Canada)"
```

#### Views [coming soon]

Add the controllers and views to your app and customize away.

```ruby
rails generate intel:engine
```

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/intel/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/intel/pulls)
- Write, clarify, or fix documentation
- Suggest or add new feature
