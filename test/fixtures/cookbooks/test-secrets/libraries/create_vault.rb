#
# Simulate a pre-created vault secret
#
item = ChefVault::Item.new('vault', 'secret')
item.raw_data = { 'id' => 'secret', 'password' => 'SecretPassword' }
item.search('*:*')
item.admins('hydroelectric')
item.save
Chef::Log.info('Created a Chef Vault')
