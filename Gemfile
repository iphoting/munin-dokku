# frozen_string_literal: true

source "https://rubygems.org"
ruby File.read('.ruby-version', mode: 'rb').chomp
#ruby-gemset=munin

gem 'rack'
gem 'rack-ssl-enforcer'
gem 'rack-timeout'
gem 'rackstaticapp'

group :development do
  gem "puma"
end

group :production do
	gem "iodine"
end
