$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))



module ActionController
  module RequestForgeryProtection
    def form_authenticity_token
      raise 'wrong form_authenticity_token method'
    end
  end
end


require 'rspec'
require 'subdomainbox'
require 'secure_xsrf_token'
require 'bundler'
Bundler.require
require 'pry'
require 'pry-nav'
require 'pry-stack_explorer'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end
