# # To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html
resource_name :act_createhost
provides :act_createhost
property :hostname, String, name_property: true
property :name, String, default: 'test'
property :enableCBT, kind_of: [TrueClass, FalseClass], default: true
property :actifioHost, String
property :username, String
property :password, String
property :vendorkey, String
property :IQN, String
property :type, String, default: 'generic'
property :session_id, String

action :create do # rubocop:disable Metrics/BlockLength
  ruby_block 'Create new host' do
    block do
      # sess_id = Actifio::Helper.login(new_resource.username,
      #                                 new_resource.password,
      #                                 new_resource.vendorkey,
      #                                 new_resource.actifioHost)
      body = { hostname:  new_resource.hostname,
               iscsiname: new_resource.IQN,
               type:      new_resource.type,
               sessionid: new_resource.session_id }.to_json
      url = 'https://' + new_resource.actifioHost + '/actifio/api/task/mkhost'
      hostid = Actifio::Helper.http_helper(url, body)
      node.run_state['hostid'] = hostid['result']
      node.run_state['sessionID'] = new_resource.session_id
      node.default['actifio']['host_id'] = hostid['result']
    end
  end

  ruby_block 'add cbt to host' do
    only_if { new_resource.enableCBT == true }
    block do
      puts 'host id is : ' + node.run_state['hostid'].to_s
      url = 'https://' + new_resource.actifioHost + '/actifio/api/task/chhost'
      body = { argument:  node.run_state['hostid'].to_s,
               blockcbt:  'enabled',
               sessionid: node.run_state['sessionID'] }.to_json
      hostmod = Actifio::Helper.http_helper(url, body)
      hostmod['result']
    end
  end
  if node.platform?('windows')
    ruby_block 'discover application' do
      block do
        puts 'host id is : ' + node.run_state['hostid'].to_s
        url = 'https://' + new_resource.actifioHost + '/actifio/api/task/appdiscovery'
        body = { host:      node.run_state['hostid'].to_s,
                 sessionid: node.run_state['sessionID'] }.to_json
        hostmod = Actifio::Helper.http_helper(url, body)
        hostmod['result']
      end
    end
  end
end
