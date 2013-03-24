subdomainbox
============

Subdomain boxing was inspired by Egor Homakov's [post on pageboxing](http://homakov.blogspot.com/2013/02/pagebox-website-gatekeeper.html). Subdomain boxing limits the reach of any XSS attacks. If an attacker manages to insert javascript onto a page of your application, the javascript on that page will be unable to read data from or post data to any pages on different subdomains in your application. POST protection is achieved by creating a separate CSRF token for each subdomain. CSRF protection is also strengthened by changing the CSRF token based on session id (request.session_options[:id]).

The subdomainbox gem is simple to add even to existing Rails applications:

    class ApplicationController

      # set up a default subdomain box for all controllers that won't get an explicit subdomain box
      # this protects regular pages that don't get a dedicated subdomain box from being accessed
      # from a subdomain boxed page
      default_subdomainbox ''

      ...

    end


    class PostsController < ApplicationController

      subdomainbox 'posts', :only => :index
      subdomainbox ['posts-%{id}', 'comments-%{pop_id}'], :except => :index

      ...

    end


    class Admin::PostsController < ApplicationController

      subdomainbox 'admin', :only => :index
      subdomainbox 'admin-%{post_id}', :except => :index

      ...

    end


    class AvatarIcon < ApplicationController

      # for controllers that need to be accessed from many places, that don't need boxing
      # protection, the default subdomain box can be removed (thereby allowing ajax calls
      # from any subdomain)
      remove_default_subdomainbox

      ...

    end

There is no need to adjust your routes or your path / url helpers. Subdomainbox automatically redirects the browser as needed based on your subdomainbox directives.


Installation
============

i Add subdomainbox to your gemfile and bundle install
i Run the generator (for generating the CSRF token secret):
    $ rails generate subdomainbox
i Make sure the root domain of your application has a wildcard SSL certificate
i Set the domain of your session cookie to the root domain
    if Rails.env.development?
      cookie_domain = 'lvh.me'
    elsif Rails.env.production?
      cookie_domain = 'mydomain.com'
    end
    MyApp::Application.config.session_store :cookie_store, key: '_myapp_session', :domain => cookie_domain

Development
===========

Use lvh.me:3000 instead of localhost:3000 since localhost doesn't support subdomains

Testing
=======

In controller specs:

    controller.stub(:subdomainbox)


To make request/feature/integration specs work:

    brew install dnsmasq
    mkdir -pv $(brew --prefix)/etc/
    echo 'address=/.dev/127.0.0.1' > $(brew --prefix)/etc/dnsmasq.conf
    sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
    sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
    sudo mkdir -v /etc/resolver
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev'

-- source [http://www.echoditto.com/blog/never-touch-your-local-etchosts-file-os-x-again](http://www.echoditto.com/blog/never-touch-your-local-etchosts-file-os-x-again)

Contributing to subdomainbox
============================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Credits
=======

Written by Daniel Nelson. Inspired by Egor Homakov's [post on pageboxing](http://homakov.blogspot.com/2013/02/pagebox-website-gatekeeper.html).
