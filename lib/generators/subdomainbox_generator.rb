class SubdomainboxGenerator < Rails::Generators::Base

  def create_initializer_file
    create_file "config/initializers/csrf_token_secret.rb", "CSRF_TOKEN_SECRET = '#{SecureRandom.base64(48)}'"
  end

end