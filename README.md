# Actifio Chef Resources

Custom resource to enable interaction with Actifio using Chef.   
At present, these resources will allow you to do the following :  
* Authenticate to Actifio Sky Appliance (and receive a valid session ID back)
* Check if a host exists
* Configure ISCSI on windows or linux
* Install the actifio connector (windows or linux)
* Configure actifio (enable LUN rescan, configure Azure WAAGENT)
* Enable CBT
* Create a new host in Actifio
* Mount a database (informix and SQL DBs are tested with this cookbook)

Note that these resources require the Actifio user password and vendor key to be provided. These should not be stored in clear text (as seen in the examples below).

## Usage
### Login and Check host
```ruby
act_login 'Auth to Actifio' do
  action :login
  actifioHost 'actifio.myexample.com'
  actifio_username 'admin'
  actifio_password 'ShhItsSecret'
  vendorkey 'xxxxx-xxxxx-xxxx-xxxx'
  hostname Chef::Config[:node_name]
end
```
This will return a hostExists attribute : `node.run_state['hostExists']`

This can be used to build guards into other resources to ensure idempotency.
#### Properties
<b>actifioHost</b>:  Hostname of actifio sky appliance
<b>actifio_username</b>: Actifio username   
<b>actifio_password</b>: Actifio password   
<b>vendorkey</b>: Actifio provided vendorkey   
<b>hostname</b>: Hostname of the node you wish to interact with Actifio. This will also check the existance of this in the sky appliance.   

### Install Connector
```ruby
act_install do
  actifioHost 'actifio.myexample.com'
end
```
This will check the OS platform and install the right binary base on Linux or Windows.
#### Properties
<b>actifioHost</b>:  Hostname of actifio sky appliance



### Setup ISCSI
Note: this was added as some cloud vm's will provide the same IQN for all deployed instances from a gold image. This will enable a random iqn to be created.

```ruby
act_iscsi 'setup iscsi' do
  only_if { !node.run_state['hostExists'] }
  generateISCSI true
  action :setup
end
```
#### Properties
<b>generateISCSI</b>:  generate a random IQN

### Create Host
```ruby
act_createhost Chef::Config[:node_name] do
  only_if { !node.run_state['hostExists'] }
  action :create
  session_id lazy { node.run_state['sessionID'] }
  actifioHost 'actifio.myexample.com'
  enableCBT true
  IQN lazy { node.run_state['initiator'] }
end
```

A couple of things about this resource...We are making the session id available to all resources as a run_state attribute. This ensures that this isnt stored as part of the nodes attributes. To access this in the compilation phase however, we need to use lazy evaluation (see https://docs.chef.io/resource_common.html#lazy-attribute-evaluation)

We do the same thing with the IQN.

#### Properties
<b>actifioHost</b>:  Hostname of actifio sky appliance   
<b>enableCBT</b>: Enable CBT on host   
<b>session_id</b>: Active session id (this will be provided by lazy evaulation of `node.run_state['sessionID']` )       
<b>IQN</b>: IQN of host (if using IQN generation, use lazy evaluation of the `node.run_state['initiator']` attribute)

### Mount database

#### Linux
```ruby
act_mount do
  host_id lazy { node['actifio']['host_id'] }
  only_if { !node.run_state['hostExists'] }
  action :mount
  session_id lazy { node.run_state['sessionID'] }
  appID '12345'
  actifioHost 'actifio.myexample.com'
end
```

In this example we need to specify the appID for the application you want to mount. 

#### Windows
```ruby
act_mount do
  host_id lazy { node['actifio']['host_id'] }
  only_if { !node.run_state['hostExists'] }
  action :mount
  session_id lazy { node.run_state['sessionID'] }
  parts 'MyDB'
  windows_restore_option "mountpointperimage=C:\\MYDB\\mydb,provisioningoptions=<provisioningoptions><recover>true</recover><username>mydb</username><password>itsameactifio</password><dbname>MyDB</dbname><sqlinstance>#{node.name}</sqlinstance></provisioningoptions>"
  appID '12345'
  actifioHost node['actifio']['host']
end
```
For SQL server, we need to add more details. Specifically the parts we want to mount the restore options xml.




