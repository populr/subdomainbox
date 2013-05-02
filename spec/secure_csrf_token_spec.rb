require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActionController::RequestForgeryProtection" do
  include ActionController::RequestForgeryProtection
  let(:request) { double('request') }
  let(:session) { {} }

  before(:each) do
    request.stub(:subdomain).and_return('pets')
    request.stub_chain(:session_options, :[]).and_return('abc')
  end

  describe "#form_authenticity_token" do

    context "when CSRF_TOKEN_SECRET is blank" do
      it "should raise an exception" do
        CSRF_TOKEN_SECRET = ''
        lambda {
          form_authenticity_token
        }.should raise_error
      end
    end

    context "when the user has a session" do
      before(:each) do
        request.stub_chain(:session_options, :[]).and_return('abc')
      end

      it "should be generated from the CSRF_TOKEN_SECRET salted with the session id and the subdomain" do
        CSRF_TOKEN_SECRET = 'xyz'
        form_authenticity_token.should == Digest::SHA1.hexdigest('xyzabcpets')
      end

      context "when the default subdomainbox has been removed" do
        it "should call the original form_authenticity_token" do
          @default_subdomainbox_removed = true
          self.should_receive(:original_form_authenticity_token)
          form_authenticity_token
        end
      end

    end

    context "when there is no session id" do
      it "should call the original form_authenticity_token" do
        request.stub_chain(:session_options, :[]).and_return(nil)
        self.should_receive(:original_form_authenticity_token)
        form_authenticity_token
      end
    end

  end

end
