source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "combustion"
gem "activerecord", "~> 7.1.0"
gem "searchkick"
gem "elasticsearch"

case ENV["ADAPTER"]
when "postgresql"
  gem "pg"
when "mysql2"
  gem "mysql2"
else
  gem "sqlite3", "< 2"
end
