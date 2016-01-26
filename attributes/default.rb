# Disable DataBag fallback in the chef-vault cookbook
default['chef-vault']['databag_fallback'] = false

# The version of chef-vault has to be the same as the bundled version
default['chef-vault']['version'] = '2.7.1'
