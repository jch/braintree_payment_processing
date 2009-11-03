require 'cgi'

module Braintree
  class Response
    attr_accessor :raw
    
    def initialize(rest_client_response)
      @raw = CGI.parse(rest_client_response)
    end

    def success?
      return false if @raw.empty?
      @raw["response"][0] == "1" && self.code == "100"
    end

    def text
      return '' if @raw.empty?
      @raw["responsetext"][0]
    end
    alias_method :responsetext, :text
    alias_method :message, :text

    def code
      return '' if @raw.empty?
      @raw["response_code"][0]
    end
    alias_method :response_code, :code

    # ask the raw response for unknown values
    def method_missing(name)
      name = name.id2name
      if @raw.has_key?(name)
        return @raw[name][0]
      else
        super
      end
    end
    
  end
end

Braintree::Response::SUCCESS_RESPONSE = Braintree::Response.new("response=1&response_code=100")