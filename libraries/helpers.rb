#
# Load Chef Vault gem, fallback to bundled
#
begin
  require 'chef-vault'
rescue LoadError
  require_relative 'chef-vault'
end

#
# Extra helpers for Chef Vault
#
module ChefVaultCookbook
  def chef_vault_item_is_vault?(bag, id)
    ChefVault::Item.vault?(bag, id)
  rescue Net::HTTPServerException => http_error
    http_error.response.code == '404' ? false : raise(http_error)
  end

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
      fail "Cannot load vault item #{id} from #{bag}, and no default value is defined"
    end
  end
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
    alias_method :chef_secret_old_save, :save unless defined?(chef_secret_old_save)

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
