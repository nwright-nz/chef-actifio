# To learn more about Custom Resources, see https://docs.chef.io/custom_resources.html

resource_name :act_iscsi
provides :act_iscsi
property :name, String, default: 'Actifio iscsi config'
property :generateISCSI, kind_of: [TrueClass, FalseClass], default: true

action :setup do # rubocop:disable Metrics/BlockLength
  if node.platform?('windows')
    require 'chef/mixin/powershell_out'
    ::Chef::Recipe.send(:include, Chef::Mixin::PowershellOut)
    windows_service 'MSiSCSI' do
      action [:enable, :start] # rubocop:disable Style/SymbolArray
      startup_type :automatic
    end
    script = <<-CODE
        (Get-InitiatorPort).NodeAddress
    CODE
    iqn = powershell_out(script)
    node.run_state['initiator'] = iqn.stdout
  else
    execute 'Generate new IQN' do
      only_if { new_resource.generateISCSI == true }
      command 'newiscsi=`sudo iscsi-iname` && sudo sed -i "/InitiatorName=/c\\InitiatorName=$newiscsi" /etc/iscsi/initiatorname.iscsi'
      action :run
    end
    ruby_block 'get iscsi initiator name' do
      # only_if { node.run_state['host_exists'] == 'false' }
      block do
        file = ::File.open('/etc/iscsi/initiatorname.iscsi', 'r')
        file.readlines.each do |line|
          _, initiator = line.delete("\n", '').split('=')
          node.run_state['initiator'] = initiator
        end
      end
    end
    service 'iscsid' do
      action [:enable, :restart] # rubocop:disable Style/SymbolArray
    end
    service 'iscsi' do
      action :restart
    end
  end
end
