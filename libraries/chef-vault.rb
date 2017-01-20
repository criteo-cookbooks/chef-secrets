# rubocop:disable Style/FileName
#
require 'chef/search/query'
require 'chef/version'
require 'chef/config'
require 'chef/api_client'
require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'chef/user'
#
# This has to be in flat files because of:
# https://github.com/chef/chef-zero/issues/161
#
require_relative 'chef-vault_exceptions'
require_relative 'chef-vault_item'
require_relative 'chef-vault_item_keys'
require_relative 'chef-vault_user'
require_relative 'chef-vault_certificate'
require_relative 'chef-vault_chef_api'
require_relative 'chef-vault_actor'
#
# Bundled ChefVault
#
class ChefVault
  attr_accessor :vault

  def initialize(vault, chef_config_file = nil)
    @vault = vault
    ChefVault.load_config(chef_config_file) if chef_config_file
  end

  def user(username)
    ChefVault::User.new(vault, username)
  end

  def certificate(name)
    ChefVault::Certificate.new(vault, name)
  end

  def self.load_config(chef_config_file)
    Chef::Config.from_file(chef_config_file)
  end

  class Log
    extend Mixlib::Log
  end

  Log.level = :error
end
