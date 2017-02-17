module Consul
   module Helper
      require 'net/http'
      require 'uri'
      def service_registered?(service)
         uri = URI.parse("http://localhost:8500/v1/catalog/services")
         request = Net::HTTP::Get.new(uri)
         response = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(request)
         end
         body = Chef::JSONCompat.parse(response.body)
         return body.has_key? (service)
      end
   end
end