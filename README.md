# Intel

:monkey_face: Search analytics made easy

[See it in action](http://intel-demo.herokuapp.com/)

- view searches in real-time
- track conversions week over week
- monitor the performance of top searches

:cupid: An amazing companion to [Searchkick](https://github.com/ankane/searchkick)

Works with Rails 3.1+ and any search engine, including Elasticsearch, Sphinx, and Solr

## Get Started

Add this line to your application’s Gemfile:

```ruby
gem "intel"
```

And run the generator. This creates a migration to store searches.

```sh
rails generate intel:install
rake db:migrate
```

Next, add the dashboard to your `config/routes.rb`.

```ruby
mount Intel::Engine, at: "admin/intel"
```

Be sure to protect the endpoint in production - see the [Authentication](#authentication) section for ways to do this.

### Track Searches

Track searches by creating a record in the database.

```ruby
Intel::Search.create(
  search_type: "Item", # typically the model name
  query: "apple",
  results_count: 12
)
```

With [Searchkick](https://github.com/ankane/searchkick), you can use the `track` option to do this automatically.

```ruby
Item.search "apple", track: true
```

If you want to track more attributes, add them to the `intel_searches` table.  Then, pass the values to the `track` option.

```ruby
Item.search "apple", track: {user_id: 1, source: "web"}
```

It’s that easy.

### Track Conversions

Tracking conversions is super important.

First, define your conversion metric. This is specific to your application.

Next, when a user searches, keep track of the search id.

```ruby
@items = Item.search "apple", track: true
@items.search.id # returns search id
```

When a user converts, mark it.

```ruby
search = Intel::Search.find params[:search_id]
search.converted_at = Time.now
search.save
```

Better yet, record the result that converted.

```ruby
item = Item.find params[:item_id]
search.convertable = item
search.save
```

The item will appear in the live stream. Add the `intel_name` method to your model to change what is displayed.

```ruby
class Item < ActiveRecord::Base
  def intel_name
    title # use the title method
  end
end
```

### Authentication

Don’t forget to protect the dashboard in production.

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

### Customize

#### Time Zone

By default, Intel uses `Time.zone`. To set a specific zone, create an initializer `config/initializers/intel.rb` with:

```ruby
Intel.time_zone = "Pacific Time (US & Canada)"
```

#### Top Searches

By default, Intel shows the top 100 searches.

```ruby
Intel.top_count = 500
```

#### Views

Coming soon

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/intel/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/intel/pulls)
- Write, clarify, or fix documentation
- Suggest or add new feature
