class SubdomainboxGenerator < Rails::Generators::Base

  def create_initializer_file
    create_file "config/initializers/xsrf_token_secret.rb", "XSRF_TOKEN_SECRET = #{SecureRandom.base64(128)}"
  end

end