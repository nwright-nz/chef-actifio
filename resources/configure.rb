# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html
resource_name :act_configure
provides :act_config

property :name, String, default: 'Configure Actifio connector'

action :configure do
  ruby_block 'configure lun rescan' do
    block do
      file = Chef::Util::FileEdit.new('/act/config/connector.conf')
      file.search_file_replace(/# - SelectiveLunRescan.*/,
                               'SelectiveLunRescan = false')
      file.write_file
    end
  end

  template '/act/scripts/remount.sh' do
    source 'remount.sh.erb'
    mode '0755'
    action :create
  end

  execute 'configure_waagent' do
    command 'sudo sed -i "s/AutoUpdate.Enabled=n/AutoUpdate.Enabled=y/g" /etc/waagent.conf'
    action :run
  end
end
