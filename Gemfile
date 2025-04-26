source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "combustion"
gem "activerecord", "~> 8.0.0"
gem "searchkick"
gem "elasticsearch"

case ENV["ADAPTER"]
when "postgresql"
  gem "pg"
when "mysql2"
  gem "mysql2"
when "trilogy"
  gem "trilogy"
else
  gem "sqlite3", platform: :ruby
  gem "sqlite3-ffi", platform: :jruby
end
