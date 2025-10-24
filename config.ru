#!/usr/bin/env ruby
require 'rubygems'
require 'gollum/app'
require 'yaml'
require 'rack/session/cookie'

# Load our patched auth middleware instead of the gem
require_relative 'gollum_auth_patch'

# Custom macro
module Gollum
  class Macro
    class NavigationNoTemplates < Gollum::Macro
      def render(title = "Navigate this directory", toc_root_path = ::File.dirname(@page.url_path), full_path = false)
        pages = @wiki.pages
        if pages.size > 0
          prepath = @wiki.base_path.sub(/\/$/, '')
          list_items = pages.map do |page|
            # Skip template files
            next if page.name =~ /_Template\.md$/i || page.filename =~ /_Template\.md$/i

            if toc_root_path == '.' || page.url_path =~ /^#{toc_root_path}\//
              path_display = (full_path || toc_root_path == '.') ? page.url_path : page.url_path.sub(/^#{toc_root_path}\//,"").sub(/^\//,'')
              "<li><a href=\"#{CGI::escapeHTML(prepath + "/" + page.escaped_url_path)}\">#{CGI::escapeHTML(path_display)}</a></li>"
            end
          end.compact # Remove nil entries from skipped templates
          result = "<ul>#{list_items.join}</ul>"
        end
        "<div class=\"toc\"><div class=\"toc-title\">#{title}</div>#{result}</div>"
      end
    end
  end
end

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
    httponly: true,
    path: '/',
    max_age: 86400 # 24 hours

# Apply authentication middleware
# This must be loaded BEFORE Precious::App
use Gollum::Auth, users, auth_options

# TemplateFilter to return the current date
# DIN 5008
Gollum::TemplateFilter.add_filter('{{current_date}}', & -> () { Time.now.strftime("%d.%m.%Y") })
# ISO-8601
# Gollum::TemplateFilter.add_filter('{{current_date}}', & -> () { Time.now.strftime("%Y-%m-%d") })

# TemplateFilter to return the current page
Gollum::TemplateFilter.add_filter("{{page_name}}", & -> (page) { page.name })


# Configure Gollum
gollum_path = '/wiki'
wiki_options = {
  allow_uploads: true,
  per_page_uploads: true,
  live_preview: false,
  h1_title: true,
  universal_toc: false,
  template_page: true,
}

Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:wiki_options, wiki_options)

run Precious::App
