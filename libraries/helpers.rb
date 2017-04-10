require "chef/mixin/shell_out"

include Chef::Mixin::ShellOut

chef_vault_version = '2.8.0'

def install_chef_vault(version)
  # this code is stolen from chef/cookbook/gem_installer
  env_path = ENV["PATH"].dup || ""
  existing_paths = env_path.split(File::PATH_SEPARATOR)
  existing_paths.unshift(RbConfig::CONFIG["bindir"])
  env_path = existing_paths.join(File::PATH_SEPARATOR)
  env_path.encode("utf-8", invalid: :replace, undef: :replace)

  Chef::Log.info "Installing chef-vault #{version}"
  if defined?(ChefSpec)
    Chef::Log.warn "Won't install gem on user system. Will rely on chef-vault being in the Gemfile of the repository"
  else
    shell_out!(%(gem install chef-vault -v "#{version}"), env: { "PATH" => env_path })
    Gem.clear_paths
  end
end

# special treatment to workaround bugs from "gem" feature in cookbook metadata
# https://github.com/chef/chef/issues/6038
begin
  gem 'chef-vault', "= #{chef_vault_version}"
rescue Gem::LoadError => e # another version has already been loaded
  case e.message
  when /could not find/i
    install_chef_vault(chef_vault_version)
  when /already activated/i
    raise "Another version of chef-vault has been loaded, aborting. #{e.message}"
  else
    raise
  end
end

require 'chef-vault'

Chef::Log.warn "Using chef-vault #{ChefVault::VERSION}"

#
# Extra helpers for Chef Vault
#
module ChefVaultCookbook
  def chef_vault_item_is_vault?(bag, id)
    ChefVault::Item.vault?(bag, id)
  rescue Net::HTTPServerException => http_error
    http_error.response.code == '404' ? false : raise(http_error)
  end

  # rubocop:disable Metrics/MethodLength
  def chef_vault_item_or_default(bag, id, default = nil)
    if chef_vault_item_is_vault?(bag, id)
      begin
        ChefVault::Item.load(bag, id)
      rescue ChefVault::Exceptions::SecretDecryption
        !default.nil? ? default : raise
      end
    elsif !default.nil?
      default
    else
      raise "Cannot load vault item #{id} from #{bag}, and no default value is defined"
    end
  end
  # rubocop:enable Metrics/MethodLength
end

Chef::Node.send(:include, ChefVaultCookbook)
Chef::Recipe.send(:include, ChefVaultCookbook)
Chef::Resource.send(:include, ChefVaultCookbook)
Chef::Provider.send(:include, ChefVaultCookbook)

#
# Methods to set, memorise, and clear default attributes
#
module ChefSecretAttributes
  # Set a default attribute and store the keys in a list
  def chef_secret_attribute_set(keys, value)
    #
    # chef_secret_attribute_set(['namespace', ... , 'key'], 'value')
    #
    keys[0...-1].inject(default, :[])[keys.last] = value
    #
    # Update list of chef vault attributes
    #
    @chef_secret_attributes = [] if @chef_secret_attributes.nil?
    @chef_secret_attributes.push(keys)
  end

  # Set a default attribute to 'SECRET'
  def chef_secret_attribute_clear(keys)
    #
    # chef_secret_attribute_clear(['namespace', ... , 'key'])
    #
    keys[0...-1].inject(default, :[])[keys.last] = 'SECRET'
  end

  # Syntax sugar for accessing attributes
  #
  # secret['cookbook']['password'] = 'value'
  # ... will call ...
  # chef_vault_attribute_set(['cookbook', 'password'], 'value')
  #
  class ChefSecretAttribute
    def initialize(node, *keys)
      @node = node
      @keys = keys
    end

    def [](key)
      self.class.new(@node, *@keys, key)
    end

    def []=(key, value)
      path = @keys.dup.push(key)
      @node.chef_secret_attribute_set(path, value)
    end
  end

  def secret
    ChefSecretAttribute.new(self)
  end
end

Chef::Node.send(:include, ChefSecretAttributes)

class Chef
  # Monkeypatch Node
  class Node
    alias chef_secret_old_save save unless method_defined?(:chef_secret_old_save)

    def save
      unless @chef_secret_attributes.nil?
        @chef_secret_attributes.each do |attribute|
          Chef::Log.info("Clearing #{attribute}")
          chef_secret_attribute_clear(attribute)
        end
      end
      chef_secret_old_save
    end
  end
end
