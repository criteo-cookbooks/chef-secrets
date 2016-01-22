opts = { node_name:       'hydroelectric',
         client_key_path: ::File.join(::File.expand_path('..', Chef::Config[:config_file]),
                                      'clients', 'hydroelectric.pem') }

secret['test-secrets']['secret'] = ChefVault::Item.load('vault', 'secret', opts)['password']

Chef::Log.warn("default['test-secrets']['secret'] is set to #{default['test-secrets']['secret']}")
