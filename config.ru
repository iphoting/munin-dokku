#!/usr/bin/env rakeup
#\ -E deployment

require 'rubygems'
require 'bundler/setup'

require 'rack'
require 'rack/ssl-enforcer'

require 'vienna'

use Rack::SslEnforcer, :hsts => true, :only_environments => 'production'
use Rack::ConditionalGet
use Rack::ETag
use Rack::ContentLength
use Rack::Deflater

run Vienna::Application.new('www')
