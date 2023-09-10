#!/usr/bin/env rakeup
#\ -E deployment

require 'rubygems'
require 'bundler/setup'

require 'rack'
require 'rack/ssl-enforcer'

require 'rackstaticapp'

use Rack::SslEnforcer, :hsts => true, :only_environments => 'production'
use Rack::ConditionalGet
use Rack::ETag
use Rack::ContentLength
use Rack::Deflater

run RackStaticApp::Application.new('www')
