module ActionController
  class Base

    class SubdomainboxDomainViolation < StandardError
    end

    def self.subdomainbox(box_definitions, options={})
      prepend_before_filter(lambda { subdomainbox(box_definitions) }, options)
    end

    def self.remove_default_subdomainbox(options={})
      prepend_before_filter(:remove_default_subdomainbox, options)
    end

    def self.default_subdomainbox(box_definitions)
      before_filter(lambda { default_subdomainbox(box_definitions) }, {})
    end

    def subdomainbox(box_definitions)
      @remove_default_subdomainbox = true
      subdomain_match = subdomainbox_find_subdomain_match(box_definitions)
      subdomainbox_no_subdomain_match!(box_definitions) if subdomain_match.nil?
    end

    # for controllers that need to be accessed from many places, that don't need boxing
    # protection, the default subdomain box can be removed (thereby allowing ajax calls
    # from any subdomain)
    #
    def remove_default_subdomainbox
      @remove_default_subdomainbox = true
    end

    # set up a default subdomain box for all controllers that won't get an explicit subdomain box
    # this protects regular pages that don't get a dedicated subdomain box from being accessed
    # from a subdomain boxed page
    #
    def default_subdomainbox(box_definitions)
      subdomainbox(box_definitions) unless @remove_default_subdomainbox
    end

    private

    def subdomainbox_no_subdomain_match!(box_definitions)
      if request.format == 'text/html' && request.get?
        flash[:alert] = flash.now[:alert]
        flash[:notice] = flash.now[:notice]
        flash[:info] = flash.now[:info]

        allowed = subdomainbox_process_definitions(box_definitions)
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
        raise SubdomainboxDomainViolation.new("subdomain box: #{box_definitions}\nrequest subdomain: #{request.subdomain}")
      end
    end

    def subdomainbox_find_subdomain_match(box_definitions)
      allowed = subdomainbox_process_definitions(box_definitions)
      matches = allowed.collect do |allowed_subdomain, separator, allowed_id_name|
        subdomainbox_check_subdomain(allowed_subdomain, separator, allowed_id_name)
      end
      matches.compact.first
    end

    def subdomainbox_check_subdomain(allowed_subdomain, separator, allowed_id_name)
      return nil if allowed_subdomain == '' unless request.subdomain == ''
      allowed_prefix = "#{allowed_subdomain}#{separator}"
      return nil unless request.subdomain.index(allowed_prefix) == 0

      id = request.subdomain[allowed_prefix.length..-1]
      if allowed_id_name
        return nil if id == ''
        if params.keys.include?(allowed_id_name)
          return nil unless id == params[allowed_id_name]
        else
          params[allowed_id_name] = id
        end
      else
        return nil unless id == ''
      end
      [allowed_subdomain, separator, id]
    end

    def subdomainbox_process_definitions(box_definitions)
      allowed = []
      box_definitions = [box_definitions] unless box_definitions.is_a?(Array)
      box_definitions.each do |definition|
        discard, allowed_subdomain, separator, allowed_id_name = definition.match(/([^%]*?)(\.?)\%\{([^}]*)\}/).to_a
        allowed_subdomain = definition if allowed_subdomain.nil?
        allowed_id_name = allowed_id_name if allowed_id_name
        allowed << [allowed_subdomain, separator, allowed_id_name]
      end
      allowed
    end

  end
end