# Intel

[not ready for prime time]

Search analytics made easy

- track searches and conversions
- watch searches in real-time
- view searches with low conversions or no results

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

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/intel/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/intel/pulls)
- Write, clarify, or fix documentation
- Suggest or add new feature
