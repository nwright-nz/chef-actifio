# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html

resource_name :act_mount
provides :act_mount

property :host_id, String, name_property: true
property :name, String, default: 'test'
property :actifioHost, String
property :username, String
property :password, String
property :vendorkey, String
property :appID, String
property :session_id, String
property :windows_restore_option, String
property :parts, String
action :mount do
  if node.platform?('windows')
    ruby_block 'Mount disk to host windows' do
      block do
        body = { appid:         new_resource.appID.to_s,
                 host:          new_resource.host_id.to_s,
                 parts:         new_resource.parts.to_s,
                 restoreoption: new_resource.windows_restore_option.to_s,
                 sessionid:     new_resource.session_id.to_s }.to_json
        url = 'https://' + new_resource.actifioHost + '/actifio/api/task/mountimage'
        mountresult = Actifio::Helper.http_helper(url, body)
        puts mountresult
        mountresult['result']
        puts mountresult['result']
      end
    end
  else
    ruby_block 'Mount linux disk to host' do
      block do
        body = { appid:     new_resource.appID.to_s,
                 script:    'name=remount.sh:phase=post',
                 host:      new_resource.host_id.to_s,
                 sessionid: new_resource.session_id.to_s }.to_json
        url = 'https://' + new_resource.actifioHost + '/actifio/api/task/mountimage'
        mountresult = Actifio::Helper.http_helper(url, body)
        puts mountresult
        mountresult['result']
        puts mountresult['result']
      end
    end
  end
end

