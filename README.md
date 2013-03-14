subdomainbox
============

Description goes here.

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

Inspired by Egor Homakov's [post on pageboxing](http://homakov.blogspot.com/2013/02/pagebox-website-gatekeeper.html). Subdomain boxing does not afford the same extent of protections as page boxing, but it is much simpler to implement and still provides significant security benefits.