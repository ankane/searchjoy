# Intel

Search analytics made easy

- track searches and conversions
- watch searches in real-time [coming soon]
- view searches with low conversions or no results [coming soon]

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

Want to track more attributes?  Just add them to the `searches` table with migrations and pass the values to the `track` option.

```ruby
Item.search "apple", track: {user_id: 1, source: "web"}
```

It’s that easy!

## View the Data [coming soon]

Add the dashboards to your `config/routes.rb`.

```ruby
mount Intel::Engine => "searches"
```

Be sure to protect the endpoint in production.

[show example]

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/intel/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/intel/pulls)
- Write, clarify, or fix documentation
- Suggest or add new feature
