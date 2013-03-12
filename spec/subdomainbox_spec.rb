require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ActionController::Base do

  # default behavior:
  # subdomainbox 'mysubdomain%{pop_id}', :except => []
  # subdomainbox 'mysubdomain', :only => []
  # subdomainbox ['account', 'editor']


  # limits the id param if it exists...if it is present and not valid, then render 403
  # if no matching id param is included, it could set params[:named_id] based on the subdomain, thereby enabling removal of the id from the path

  #subdomainbox 'editor.' / ['account.', 'app.'], :only => [:index, :edit] / :except => [:update, :create]
  # default to restfulness: id limited on all xhr requests except for create and index
  # id assumed to be params[:id], but can be overridden

  # describe "#subdomainbox_url_for" do
  #   # Rails.application.routes.url_helpers
  #   context "when subdomainbox was called with a single subdomain" do
  #     it "should generate a url with domain being constructed from the root domain of the origin and the subdomain" do
  #       pending
  #     end
  #   end

  #   context "when subdomainbox was called with an array of subdomains" do
  #     it "should generate a url with domain being constructed from the root domain of the origin and the first subdomain in the array" do
  #       pending
  #     end
  #   end

  # end

  describe "#subdomainbox" do
    let(:request) { double('request') }
    let(:controller) { ActionController::Base.new }

    before(:each) do
      request.stub(:domain).and_return('peanuts.com')
      controller.stub(:request).and_return(request)
      controller.stub(:params).and_return({})
    end

    context "when the specified subdomain includes an id" do
      before(:each) do
        request.stub(:format).and_return('text/html')
        request.stub(:subdomain).and_return('pets.abc')
      end

      context "when the params include a matching id" do
        it "should not raise an exception" do
          params = { :pet_id => 'abc' }
          controller.stub(:params).and_return(params)
          lambda {
            controller.subdomainbox :allowed => 'pets.%{pet_id}'
          }.should_not raise_error
        end
      end

      context "when the params include an id that doesn't match the id in the subdomain" do
        it "should raise SubdomainboxIDViolation" do
          params = { :pet_id => 'efg' }
          controller.stub(:params).and_return(params)
          lambda {
            controller.subdomainbox :allowed => 'pets.%{pet_id}'
          }.should raise_error(ActionController::Base::SubdomainboxIDViolation)
        end
      end

      context "when the params don't include an id of the specified name" do
        it "should not raise an exception" do
          params = { :id => 'efg' }
          controller.stub(:params).and_return(params)
          lambda {
            controller.subdomainbox :allowed => 'pets.%{pet_id}'
          }.should_not raise_error
        end

        it "should set a param of the specified name on params" do
          params = {}
          controller.stub(:params).and_return(params)
          controller.subdomainbox :allowed => 'pets.%{pet_id}'
          params[:pet_id].should == 'abc'
        end
      end

    end

    context "when the requested format is html" do
      before(:each) do
        request.stub(:format).and_return('text/html')
        request.stub(:subdomain).and_return('pets')
        # request.stub(:subdomain).and_return('pets.abc')
      end

      context "when the origin subdomain is the specified subdomain" do
        it "should not raise an exception or redirect" do
          controller.should_not_receive(:redirect_to)
          lambda {
            controller.subdomainbox :allowed => 'pets'
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception or redirect" do
            request.stub(:subdomain).and_return('pets.abc')
            params = { :pet_id => 'abc' }
            controller.stub(:params).and_return(params)
            controller.should_not_receive(:redirect_to)
            lambda {
              controller.subdomainbox :allowed => 'pets.%{pet_id}'
            }.should_not raise_error
          end
        end
      end

      context "when the origin subdomain is included in the list" do
        it "should not raise an exception or redirect" do
          controller.should_not_receive(:redirect_to)
          lambda {
            controller.subdomainbox :allowed => ['activities', 'pets']
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception or redirect" do
            request.stub(:subdomain).and_return('petsabc')
            params = { :pet_id => 'abc' }
            controller.stub(:params).and_return(params)
            controller.should_not_receive(:redirect_to)
            lambda {
              controller.subdomainbox :allowed => ['activities%{pet_id}', 'pets%{pet_id}']
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
          end

          it "should redirect to the same path (including http variables) at the specified subdomain prefixing the root of the origin domain" do
            controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
            controller.subdomainbox :allowed => 'pets'
          end

          context "when the specified subdomain includes an id" do
            it "the redirection subdomain should include the id" do
              controller.should_receive(:redirect_to).with('https://pets.abc.peanuts.com:8080/pets?e=123')
              params = { :pet_id => 'abc' }
              controller.stub(:params).and_return(params)
              controller.subdomainbox :allowed => 'pets.%{pet_id}'
            end

            context "when no id param matching the specified id name exists" do
              it "the redirection subdomain should not include the id" do
                controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
                params = { :id => 'abc' }
                controller.stub(:params).and_return(params)
                controller.subdomainbox :allowed => 'pets.%{pet_id}'
              end
            end
          end

          context "when no id is specified in the subdomainbox" do
            it "the redirection subdomain should not include the id" do
              controller.should_receive(:redirect_to).with('https://pets.peanuts.com:8080/pets?e=123')
              params = { :pet_id => 'abc' }
              controller.stub(:params).and_return(params)
              controller.subdomainbox :allowed => 'pets'
            end
          end
        end

        context "when this is not a GET request" do
          it "should raise SubdomainboxDomainViolation" do
            request.stub(:get?).and_return(false)
            lambda {
              controller.subdomainbox :allowed => 'pets'
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
            controller.subdomainbox :allowed => ['activities', 'pets']
          end
        end

        context "when this is not a GET request" do
          it "should raise SubdomainboxDomainViolation" do
            request.stub(:get?).and_return(false)
            lambda {
              controller.subdomainbox :allowed => ['activities', 'pets']
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
            controller.subdomainbox :allowed => 'pets'
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception" do
            request.stub(:subdomain).and_return('pets.abc')
            lambda {
              controller.subdomainbox :allowed => 'pets'
            }.should_not raise_error
          end
        end
      end


      context "when the origin subdomain is in the specified subdomain list" do
        it "should not raise an exception" do
          request.stub(:subdomain).and_return('pets')
          lambda {
            controller.subdomainbox :allowed => ['activities', 'pets']
          }.should_not raise_error
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception" do
            request.stub(:subdomain).and_return('pets.abc')
            lambda {
              controller.subdomainbox :allowed => ['activities', 'pets']
            }.should_not raise_error
          end
        end
      end


      context "when the origin subdomain is not the specified subdomain" do
        it "should raise SubdomainboxDomainViolation" do
          # recommend using around filter to rescue these exceptions and respond accordingly from that one place
          request.stub(:subdomain).and_return('houses')
          lambda {
            controller.subdomainbox :allowed => 'pets'
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        context "when the origin subdomain includes an id" do
          it "should not raise an exception" do
            request.stub(:subdomain).and_return('houses.abc')
            lambda {
              controller.subdomainbox :allowed => 'pets'
            }.should raise_error
          end
        end
      end

      context "when the origin subdomain is not in the specified subdomain list" do
        it "should raise SubdomainboxDomainViolation" do
          request.stub(:subdomain).and_return('houses')
          lambda {
            controller.subdomainbox :allowed => ['activities', 'pets']
          }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
        end

        context "when the origin subdomain includes an id" do
          it "should raise an exception" do
            request.stub(:subdomain).and_return('houses.abc')
            lambda {
              controller.subdomainbox :allowed => ['activities', 'pets']
            }.should raise_error(ActionController::Base::SubdomainboxDomainViolation)
          end
        end
      end

    end

  end


end
