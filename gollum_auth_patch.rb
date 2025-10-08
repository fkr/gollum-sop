require 'rack/auth/basic'

module Gollum
  class Auth < Rack::Auth::Basic
    
    def initialize(app, users = [], options = {})
      @users = users
      @options = options
      super(app, "Gollum Wiki") do |username, password|
        authenticate(username, password)
      end
    end

    def call(env)
      request = Rack::Request.new(env)
      
      # Allow unauthenticated readonly access if enabled
      if @options[:allow_unauthenticated_readonly] && readonly_request?(request)
        return @app.call(env)
      end
      
      # Require authentication
      auth = super(env)
      
      # If authenticated, set the author info in session
      if env['REMOTE_USER']
        user = find_user(env['REMOTE_USER'])
        if user
          # Set in session for Gollum to pick up
          session = env['rack.session'] ||= {}
          session['gollum.author'] = {
            name: user['name'] || user[:name],
            email: user['email'] || user[:email]
          }
          
          # Also set in env for compatibility
          env['gollum.author'] = session['gollum.author']
        end
      end
      
      auth
    end

    private

    def authenticate(username, password)
      user = find_user(username)
      return false unless user
      
      if user['password']
        user['password'] == password
      elsif user['password_digest']
        require 'digest/sha2'
        Digest::SHA256.hexdigest(password) == user['password_digest']
      elsif user[:password]
        user[:password] == password
      elsif user[:password_digest]
        require 'digest/sha2'
        Digest::SHA256.hexdigest(password) == user[:password_digest]
      else
        false
      end
    end

    def find_user(username)
      @users.find do |user|
        (user['username'] || user[:username]) == username
      end
    end

    def readonly_request?(request)
      request.get? && !request.path.start_with?('/create', '/edit', '/delete', '/rename', '/revert', '/upload')
    end
  end
end
