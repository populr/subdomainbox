require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActionController::Base do

  # default behavior:
  # subdomainbox 'mysubdomain%{pop_id}', :except => []
  # subdomainbox 'mysubdomain', :only => []
  describe "#subdomainbox" do
    let(:request) { double('request') }
    let(:controller) { ActionController::Base.new }
    let(:flash) { double('flash') }
    let(:flash_now) { double('flash_now') }

    before(:each) do
      request.stub(:domain).and_return('peanuts.com')
      controller.stub(:request).and_return(request)
      controller.stub(:params).and_return({})

      flash.stub(:now).and_return(flash_now)
      flash.stub(:[]=)
      flash_now.stub(:[])
      controller.stub(:flash).and_return(flash)
    end

    context "when the specified subdomain includes an id" do
      before(:each) do
        request.stub(:format).and_return('text/html')
        request.stub(:subdomain).and_return('pets.abc')
      end

      context "when the params include a matching id" do
        it "should not raise an exception" do
          params = { 'pet_id' => 'abc' }
          controller.stub(:params).and_return(params)
          lambda {
            controller.subdomainbox('pets.%{pet_id}')
          }.should_not raise_error
        end
      end


      context "when the params don't include an id of the specified name" do
        it "should not raise an exception" do
          params = { 'id' => 'efg' }
          controller.stub(:params).and_return(params)
          lambda {
            controller.subdomainbox('pets.%{pet_id}')
          }.should_not raise_error
        end

        it "should set a param of the specified name on params" do
          params = {}
          controller.stub(:params).and_return(params)
          controller.subdomainbox('pets.%{pet_id}')
          params['pet_id'].should == 'abc'
        end
      end

    end

    context "when the requested format is html" do
      before(:each) do
        request.stub(:format).and_return('text/html')
        request.stub(:subdomain).and_return('pets')
      end

      context "when the params include an id that doesn't match the id in the subdomain" do
        it "should redirect to the subdomain + id domain" do
          request.stub(:subdomain).and_return('www')
          request.stub(:protocol).and_return('https://')
          request.stub(:port_string).and_return(':8080')
          request.stub(:fullpath).and_return('/pets?e=123')
          request.stub(:get?).and_return(true)


          params = { 'pet_id' => 'efg' }
          controller.stub(:params).and_return(params)

          controller.should_receive(:redirect_to).with('https://pets.efg.peanuts.com:8080/pets?e=123')
          request.stub(:subdomain).and_return('pets')
          controller.subdomainbox('pets.%{pet_id}')

          controller.should_receive(:redirect_to).with('https://pets.efg.peanuts.com:8080/pets?e=123')
          request.stub(:subdomain).and_return('pets.abc')
          controller.subdomainbox('pets.%{pet_id}')
        end
      end

      context "when the origin subdomain is the specified subdomain" do
        it "should not raise an exception or redirect" do
          controller.should_not_receive(:redirect_to)
          lambda {
            controller.subdomainbox('pets')
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception or redirect" do
            request.stub(:subdomain).and_return('pets.abc')
            params = { 'pet_id' => 'abc' }
            controller.stub(:params).and_return(params)
            controller.should_not_receive(:redirect_to)
            lambda {
              controller.subdomainbox('pets.%{pet_id}')
            }.should_not raise_error
          end
        end
      end

      context "when the origin subdomain is included in the list" do
        it "should not raise an exception or redirect" do
          controller.should_not_receive(:redirect_to)
          lambda {
            controller.subdomainbox(['activities', 'pets'])
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception or redirect" do
            request.stub(:subdomain).and_return('petsabc')
            params = { 'pet_id' => 'abc' }
            controller.stub(:params).and_return(params)
            controller.should_not_receive(:redirect_to)
            lambda {
              controller.subdomainbox(['activities%{pet_id}', 'pets%{pet_id}'])
            }.should_not raise_error
          end
        end
      end

      context "when the origin subdomain is not the specified subdomain" do
        before(:each) do
          request.stub(:subdomain).and_return('www')
          request.stub(:protocol).and_return('https://')
          request.stub(:port_string).and_return(':8080')
          request.stub(:fullpath).and_return('/pets?e=123')
        end

        context "when this is a GET request" do
          before(:each) do
            request.stub(:get?).and_return(true)
            controller.stub(:redirect_to)
          end

          it "should 'forward' all flash notices so that they are not lost in the redirect" do

            flash_now.should_receive(:[]).with(:alert).and_return('The alert flash')
            flash_now.should_receive(:[]).with(:notice).and_return('The notice flash')
            flash_now.should_receive(:[]).with(:info).and_return('The info flash')

            flash.should_receive(:[]=).with(:alert, 'The alert flash')
            flash.should_receive(:[]=).with(:notice, 'The notice flash')
            flash.should_receive(:[]=).with(:info, 'The info flash')

            controller.subdomainbox('pets')
          end

          it "should redirect to the same path (including http variables) at the specified subdomain prefixing the root of the origin domain" do
            controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
            controller.subdomainbox('pets')
          end

          context "when the specified subdomain is an empty string" do
            it "should redirect to the root domain" do
              controller.should_receive(:redirect_to).with('https://peanuts.com:8080/pets?e=123')
              controller.subdomainbox('')
            end
          end

          context "when the specified subdomain includes an id" do
            it "the redirection subdomain should include the id" do
              controller.should_receive(:redirect_to).with('https://pets.abc.peanuts.com:8080/pets?e=123')
              params = { 'pet_id' => 'abc' }
              controller.stub(:params).and_return(params)
              controller.subdomainbox('pets.%{pet_id}')
            end

            context "when no id param matching the specified id name exists" do
              it "the redirection subdomain should not include the id" do
                controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
                params = { 'id' => 'abc' }
                controller.stub(:params).and_return(params)
                controller.subdomainbox('pets.%{pet_id}')
              end
            end
          end

          context "when no id is specified in the subdomainbox" do
            it "the redirection subdomain should not include the id" do
              controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
              params = { 'pet_id' => 'abc' }
              controller.stub(:params).and_return(params)
              controller.subdomainbox('pets')
            end
          end
        end

        context "when this is not a GET request" do
          it "should raise SubdomainboxDomainViolation" do
            request.stub(:get?).and_return(false)
            lambda {
              controller.subdomainbox('pets')
            }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
          end
        end
      end

      context "when the origin subdomain is not in the list of approved subdomains" do
        before(:each) do
          request.stub(:subdomain).and_return('www')
          request.stub(:protocol).and_return('https://')
          request.stub(:port_string).and_return(':8080')
          request.stub(:fullpath).and_return('/pets?e=123')
        end



        context "when this is a GET request" do
          it "should redirect to the same path (http variables) at the first subdomain in the list prefixing the root of the origin domain" do
            request.stub(:get?).and_return(true)
            controller.should_receive(:redirect_to).with('https://activities.peanuts.com:8080/pets?e=123')
            controller.subdomainbox(['activities', 'pets'])
          end
        end

        context "when this is not a GET request" do
          it "should raise SubdomainboxDomainViolation" do
            request.stub(:get?).and_return(false)
            lambda {
              controller.subdomainbox(['activities', 'pets'])
            }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
          end
        end
      end


    end


    context "when the requested format is not html" do
      before(:each) do
        request.stub(:format).and_return('application/json')
      end


      context "when the origin subdomain is the specified subdomain" do
        it "should not raise an exception" do
          request.stub(:subdomain).and_return('pets')
          lambda {
            controller.subdomainbox('pets')
          }.should_not raise_error
        end
      end


      context "when the origin subdomain is in the specified subdomain list" do
        it "should not raise an exception" do
          request.stub(:subdomain).and_return('pets')
          lambda {
            controller.subdomainbox(['activities', 'pets'])
          }.should_not raise_error
        end
      end


      context "when the origin subdomain is not the specified subdomain" do
        it "should raise SubdomainboxDomainViolation" do
          # recommend using around filter to rescue these exceptions and respond accordingly from that one place
          request.stub(:subdomain).and_return('houses')
          lambda {
            controller.subdomainbox('pets')
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception" do
            request.stub(:subdomain).and_return('houses.abc')
            lambda {
              controller.subdomainbox('pets')
            }.should raise_error
          end
        end
      end

      context "when the origin subdomain is not in the specified subdomain list" do
        it "should raise SubdomainboxDomainViolation" do
          request.stub(:subdomain).and_return('houses')
          lambda {
            controller.subdomainbox(['activities', 'pets'])
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        context "when the origin subdomain includes an id" do
          it "should raise an exception" do
            request.stub(:subdomain).and_return('houses.abc')
            lambda {
              controller.subdomainbox(['activities', 'pets'])
            }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
          end

          it "the exception message should indicate the allowed and the requested subdomains" do
            request.stub(:subdomain).and_return('houses.abc')
            begin
              controller.subdomainbox(['activities', 'pets'])
            rescue ActionController::Base::SubdomainboxDomainViolation => e
              e.message.should include('["activities", "pets"]')
              e.message.should include('houses.abc')
            end
          end
        end
      end

      context "when the subdomainbox specifies no id, but the current subdomain includes an id" do
        it "should raise an exception (eg: a specific post is trying to reach the index of posts)" do
          request.stub(:subdomain).and_return('pets-abc')
          lambda {
            controller.subdomainbox('pets')
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end
      end

      context "when the subdomainbox specifies multiple subdomains, some with an id, some without an id" do
        it "should raise an exception whenever the subdomain includes an id but matches a subdomainbox that specifies no id" do
          request.stub(:subdomain).and_return('pets-abc')
          lambda {
            controller.subdomainbox(['pets', 'houses-%{id}'])
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        it "should raise an exception whenever the subdomain omits an id but matches a subdomainbox that specifies an id" do
          request.stub(:subdomain).and_return('houses')
          lambda {
            controller.subdomainbox(['pets', 'houses-%{id}'])
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        it "should not raise an exception whenever the subdomain includes an id and matches a subdomainbox that specifies an id" do
          request.stub(:subdomain).and_return('houses-abc')
          lambda {
            controller.subdomainbox(['pets', 'houses-%{id}'])
          }.should_not raise_error
        end

        it "should not raise an exception whenever the subdomain omits an id and matches a subdomainbox that specifies no id" do
          request.stub(:subdomain).and_return('pets')
          lambda {
            controller.subdomainbox(['pets', 'houses-%{id}'])
          }.should_not raise_error
        end
      end

    end

  end

end
