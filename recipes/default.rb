#
# Cookbook Name:: chef-secrets
# Recipe:: default
#
# Copyright (c) 2016 Criteo, All Rights Reserved.

include_recipe 'chef-vault'

# hide secrets by default
directory ::File.join(Chef::Config[:cache_path], 'chef-secrets-cache') do
  recursive true
  case node['os']
  when 'linux'
    owner 'root'
    group 'root'
    mode '0700'
  when 'windows'
    owner 'SYSTEM'
    inherits false
    rights :full_control, 'SYSTEM'
  end
end
