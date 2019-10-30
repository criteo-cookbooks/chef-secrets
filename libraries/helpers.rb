require 'json'
require 'chef/node'

require 'chef-vault'

Chef::Log.info "Using chef-vault #{ChefVault::VERSION}"

#
# Extra helpers for Chef Vault
#
module ChefVaultCookbook
  def chef_vault_item_is_vault?(bag, id)
    ChefVault::Item.vault?(bag, id)
  rescue Net::HTTPServerException => http_error
    http_error.response.code == '404' ? false : raise(http_error)
  end

  def chef_vault_item_exists?(bag, id)
    @existing_items ||= {}
    return @existing_items["#{bag}::#{id}"] if @existing_items.key?("#{bag}::#{id}")
    @existing_items["#{bag}::#{id}"] = begin
                                         Chef::DataBagItem.load(bag, id)
                                         true
                                       rescue Net::HTTPServerException => http_error
                                         puts http_error.response.code
                                         http_error.response.code.to_i == 404 ? false : raise
                                       end
  end

  # rubocop:disable Metrics/MethodLength
  def chef_vault_item_or_default(bag, id, default = nil)
    if chef_vault_item_exists?(bag, id)
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

module ClearSecretsBeforeSaving
  def save
    unless @chef_secret_attributes.nil?
      @chef_secret_attributes.each_with_index do |attribute, i|
        Chef::Log.info("Clearing #{attribute} and #{@chef_secret_attributes.size - 1} others") if i.zero?
        Chef::Log.debug("Clearing #{attribute}")
        chef_secret_attribute_clear(attribute)
      end
    end
    super
  end
end

::Chef::Node.prepend ClearSecretsBeforeSaving
