# chef-secrets cookbook

This cookbook aims to ease `chef-vault` interaction by providing additional helpers, and testing the functionality on a Linux and Windows box.

More info about `chef-vault`: https://github.com/chef-cookbooks/chef-vault

## Usage pattern (with wrapper cookbooks)

Let us say you are using a cookbook that requires you to set a password in an attribute. This attribute is usually set in a wrapper cookbook which includes the original cookbook. By including this cookbook as well, you can set the attribute in the wrapper cookbook's attribute file like this:
```ruby
secret['cookbook']['password'] = chef_vault_item_or_default('vault', 'item')
```
This will set the attribute `default['cookbook']['password']` to the `item` from the `vault`. It will also set the attribute to `SECRET` at the end of the Chef run, therefore ensuring that the Chef Server will not contain the password in plaintext. If the item in the vault does not exist it will **fail**.

If you would like to default to a value in a testing environment, you can do:
```ruby
fallback = Mash.new({ key: 'fallback' }) if ENV['TEST_KITCHEN'] || defined?(ChefSpec) || Chef::Config[:local_mode]

secret['cookbook']['password'] = chef_vault_item_or_default('vault', 'item', fallback)

# use it anywhere with node['cookbook']['password']['key']
```

Note that a chef-vault item will always be a hash, so it may be better to set the fallback to a similar hash as well.

## Caching

Accessing many secrets on high latency links can be very long.
`chef_vault_item_or_default` helper is able to cache for a few hours decrypted value on chef cache.

Call it with `chef_vault_item_or_default('vault', 'item', fallback, use_cache: true)`.

Cached entry has a TTL set randomly between 1 and 12 hours.

## Secret attributes

### Overview

Secret attributes are node attributes that are available only during the Chef run, but set to `SECRET` when saved and uploaded to the Chef Server. These attributes are actually default node attributes set through a helper method, so you may access them as you would access any default node attribute.

### Usage
Set a secret in cookbook attributes:
```ruby
secret['cookbook']['password'] = 'SuperSecretPassword'
```
Read it anywhere like a default node attribute:
```ruby
Chef::Log.info("This is my password: #{node['cookbook']['password']}")
```
_Note_: Please don't accidentally save your secrets in the Chef log file :)

### Call stack
When called with this syntax
```ruby
secret['cookbook']['password'] = 'SuperSecretPassword'
```
actually calls
```ruby
chef_secret_attribute_set(['cookbook', 'password'], 'SuperSecretPassword')
```
which in turn sets
```ruby
default['cookbook']['password'] = 'SuperSecretPassword'
```
and will be cleared at the end by
```ruby
chef_secret_attribute_clear(['cookbook', 'password'])
```
which sets
```ruby
default['cookbook']['password'] = 'SECRET'
```

## Additional `chef-vault` helpers

### chef_vault_item_or_default
Get an item from the vault, or default to value if if the vault or item does not exist. If the default value is not specified, it will fail the Chef run.
```ruby
chef_vault_item_or_default('vault', 'item', 'default') 
```

### chef_vault_item_is_vault?
Return true if item is a vault item. Note that unlike `ChefVault::Item.vault?`, this method returns false if the data bag does not exist.
```ruby
chef_vault_item_is_vault?('vault', 'item')
```
