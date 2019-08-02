# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html
resource_name :act_install
provides :act_install

property :actifioHost, String
property :name, String, default: 'actifio install'

action :install do
  if node.platform?('windows')
    remote_file './actifio-install.exe' do
      source 'https://' + new_resource.actifioHost + '/connector-Win32-latestversion.exe'
      action :create
    end
    execute 'install windows actifio connector' do
      command './actifio-install.exe /SUPPRESSMSGBOXES /NORESTART /VERYSILENT /TYPE=full /LOG="Actifio_agent_install.log"'
    end
  else
    remote_file './actifio-install.rpm' do
      source 'https://' + new_resource.actifioHost + '/connector-Linux-latestversion.rpm'
      mode '0755'
      action :create
    end
    rpm_package 'actifio-install.rpm' do
      source './actifio-install.rpm'
      action :install
    end
  end
end
