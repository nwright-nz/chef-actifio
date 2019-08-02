module Actifio
  module Helper
    def self.http_helper(requesturi, requestbody)
      require 'net/http'
      require 'json'
      uri = URI(requesturi)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = requestbody
      res = Net::HTTP.start(uri.hostname, uri.port,
                            read_timeout: 360,
                            use_ssl:      uri.scheme == 'https',
                            verify_mode:  OpenSSL::SSL::VERIFY_NONE) do |http|
        http.request(req)
      end
      JSON.parse(res.body)
    end
  end
end
