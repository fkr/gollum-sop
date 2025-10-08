#!/usr/bin/env ruby
require 'rubygems'
require 'gollum/app'
require 'yaml'
require 'rack/session/cookie'

# Load our patched auth middleware instead of the gem
require_relative 'gollum_auth_patch'

# Load users from YAML file
users = YAML.load_file('/app/users.yml')

# Options for gollum-auth
# Set allow_unauthenticated_readonly to true if you want guests to read the wiki
auth_options = { 
  allow_unauthenticated_readonly: false  # Change to true for public read access
}

# Add session support (required for gollum.author)
use Rack::Session::Cookie, 
    key: 'rack.session',
    secret: ENV['SESSION_SECRET'] || 'a' * 64, # Minimum 64 bytes required
    same_site: :lax,
    max_age: 86400 # 24 hours

# Apply authentication middleware
# This must be loaded BEFORE Precious::App
use Gollum::Auth, users, auth_options

# Configure Gollum
gollum_path = '/wiki'
wiki_options = {
  allow_uploads: true,
  per_page_uploads: true,
  live_preview: false,
  h1_title: true,
  universal_toc: false
}

Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:wiki_options, wiki_options)

run Precious::App
