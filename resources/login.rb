resource_name :act_login
provides :act_login

property :name, String, default: 'Actifio Login'
property :actifioHost, String
property :actifio_username, String
property :actifio_password, String
property :vendorkey, String
property :hostname, String

action :login do
  ruby_block 'Get session ID' do
  block do
    require 'net/http'
    require 'json'
    host = new_resource.actifioHost.to_s
    request_url = 'https://' + host + '/actifio/api/login'
    body = { name:      new_resource.actifio_username.to_s,
             password:  new_resource.actifio_password.to_s,
             vendorkey: new_resource.vendorkey.to_s }.to_json
    response = Actifio::Helper.http_helper(request_url, body)
    node.run_state['sessionid'] = response['sessionid']

    uri = URI('https://' + host + '/actifio/api/info/lshost')
    params = { sessionid:   response['sessionid'],
               filtervalue: 'hostname=' + new_resource.hostname.to_s }
    uri.query = URI.encode_www_form(params)
    req = Net::HTTP::Get.new(uri)
    res = Net::HTTP.start(uri.host,
                          uri.port,
                          read_timeout: 360,
                          use_ssl:      uri.scheme == 'https',
                          verify_mode:  OpenSSL::SSL::VERIFY_NONE) do |https|
                            https.request(req)
                          end
    json = JSON.parse(res.body)
    node.run_state['hostExists'] = true if json['result'].length >= 1
  end
end
end
