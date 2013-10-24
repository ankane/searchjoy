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
Item.search "apple", track: {user_id: true, source: "web"}
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

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
