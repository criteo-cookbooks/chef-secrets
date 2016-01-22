# chef-secrets cookbook

This cookbook is reponsible for installing the `chef-vault` cookbook with
additional helpers, and testing the functionality on a Linux and Windows box.

More info about `chef-vault`: https://github.com/chef-cookbooks/chef-vault

## Bundling Chef Vault

This cookbook bundles the chef-vault gem so that it may be used immediately at
compile time in attributes. The bundled chef-vault gem is the one tracked in a
submodule in /ext/chef-vault. To upgrade please checkout the appropriate commit
in the submodule and run `ext/bundle.sh` to copy the newest files into the
`libraries` directory.
