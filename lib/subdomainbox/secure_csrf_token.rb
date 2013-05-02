require 'digest/sha1'

module ActionController #:nodoc:

  module RequestForgeryProtection

    protected

      alias_method :original_form_authenticity_token, :form_authenticity_token
      # Sets the token value for the current session.
      def form_authenticity_token
        raise 'CSRF token secret must be defined' if CSRF_TOKEN_SECRET.nil? || CSRF_TOKEN_SECRET.empty?
        if request.session_options[:id].nil? || request.session_options[:id].empty?
          original_form_authenticity_token
        else
          Digest::SHA1.hexdigest("#{CSRF_TOKEN_SECRET}#{request.session_options[:id]}#{request.subdomain}")
        end
      end

  end
end
