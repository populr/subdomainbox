module ActionController
  class Base

    class SubdomainboxDomainViolation < StandardError
    end

    def self.subdomainbox(allowed, options={})
      before_filter(lambda { subdomainbox(:allowed => allowed) }, options)
    end

    def subdomainbox(options)
      allowed = subdomainbox_process_definitions(options)
      subdomain_match = subdomainbox_find_subdomain_match(allowed)
      subdomainbox_no_subdomain_match!(allowed) if subdomain_match.empty?
    end

    private

    def subdomainbox_no_subdomain_match!(allowed)
      if request.format == 'text/html'
        if request.get?
          flash[:alert] = flash.now[:alert]
          flash[:notice] = flash.now[:notice]
          flash[:info] = flash.now[:info]

          default_definition = allowed.first
          if default_definition.first == ''
            redirect_to(request.protocol + request.domain + request.port_string + request.fullpath)
          else
            allowed_id_name = default_definition.pop
            allowed_id_name = allowed_id_name if allowed_id_name
            default_definition << params[allowed_id_name]
            default_definition.compact!
            default_definition.pop if default_definition.length == 2

            redirect_to(request.protocol + default_definition.join + '.' + request.domain + request.port_string + request.fullpath)
          end
        else
          raise SubdomainboxDomainViolation.new
        end
      else
        raise SubdomainboxDomainViolation.new
      end
    end

    def subdomainbox_find_subdomain_match(allowed)
      allowed.each do |allowed_subdomain, separator, allowed_id_name|
        if allowed_subdomain == ''
          next unless request.subdomain.nil? || request.subdomain.empty?
        else
          next unless request.subdomain =~ /\A#{allowed_subdomain}\.?/
        end
        if allowed_id_name
          if id = request.subdomain.sub(/\A#{allowed_subdomain}\.?/, '')
            if params.keys.include?(allowed_id_name)
              return [] unless id == params[allowed_id_name]
            else
              params[allowed_id_name] = id
            end
          end
        end
        return [allowed_subdomain, separator, id]
      end
      []
    end

    def subdomainbox_process_definitions(options)
      allowed = []
      raw_definitions = options[:allowed]
      raw_definitions = [raw_definitions] unless raw_definitions.is_a?(Array)
      raw_definitions.each do |definition|
        discard, allowed_subdomain, separator, allowed_id_name = definition.match(/([^%]*?)(\.?)\%\{([^}]*)\}/).to_a
        allowed_subdomain = definition if allowed_subdomain.nil?
        allowed_id_name = allowed_id_name if allowed_id_name
        allowed << [allowed_subdomain, separator, allowed_id_name]
      end
      allowed
    end

  end
end