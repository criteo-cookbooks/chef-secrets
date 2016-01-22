# This recipe is for testing the chef_vault_secret resource.
include_recipe 'chef-secrets'

# Works both on Windows and Linux
begin
  data_bag('green')
rescue
  ruby_block 'create-data_bag-green' do
    block do
      Chef::DataBag.validate_name!('green')
      databag = Chef::DataBag.new
      databag.name('green')
      databag.save
    end
    action :create
  end
end

chef_vault_secret 'clean-energy' do
  data_bag 'green'
  raw_data('auth' => 'Forged in a mold')
  admins 'hydroelectric'
  search '*:*'
end

chef_vault_secret 'dirty-energy' do
  environment '_default'
  data_bag 'green'
  raw_data('auth' => 'carbon-credits')
  admins 'hydroelectric'
end

Chef::Log.warn("node['test-secrets']['secret'] is set to #{node['test-secrets']['secret']}")
