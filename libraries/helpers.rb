require 'json'
require "chef/mixin/shell_out"

include Chef::Mixin::ShellOut

chef_vault_version = '3.2.0'

def install_chef_vault(version)
  Chef::Log.info "Installing chef-vault #{version}"
  if defined?(ChefSpec)
    Chef::Log.warn "Won't install gem on user system. Will rely on chef-vault being in the Gemfile of the repository"
  else
    source = Array(Chef::Config[:rubygems_url] || "https://www.rubygems.org").first
    # shell_out! has funny behaviour with setting the path via the env parameter - it won't use the proper gem bin if we
    # set it that way
    shell_out!(%("#{RbConfig::CONFIG["bindir"]}/gem" install chef-vault -v "#{version}" -s #{source}))
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
    raise "Another version of chef-vault has been loaded, aborting. #{e.message}" unless defined?(ChefSpec)
    Chef::Log.warn "ChefSpec running with a version of chef-vault different than the target #{chef_vault_version}, proceeding anyway"
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
  def chef_vault_item_or_default(bag, id, default = nil, use_cache = false)
    cached_item = ItemCache.new(bag, id)
    return cached_item.value if use_cache && cached_item.cached?
    if chef_vault_item_is_vault?(bag, id)
      begin
        ChefVault::Item.load(bag, id).tap do |value|
          if use_cache
            cached_item.write(value)
          else
            cached_item.delete
          end
        end
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

  class ItemCache
    attr_reader :bag, :id

    def initialize(bag, id)
      @bag = bag
      @id = id
    end

    def ttl_in_seconds
      # ttl is between 1 and 12 hours
      [*1..12].sample * 3600
    end

    def cache_file
      ::File.join(Chef::Config[:cache_path], 'chef-secrets-cache', bag, id)
    end

    def cached?
      ::File.exist?(cache_file) && ::File.mtime(cache_file) > Time.now - ttl_in_seconds
    end

    def value
      JSON.parse(File.read(cache_file))
    rescue => e
      Chef::Log.warn "Unable to read #{cache_file}. Exception was #{e.class.name} #{e.message}"
    end

    def write(value)
      FileUtils.mkdir_p(File.dirname(cache_file))
      File.write(cache_file, value.to_json)
    end

    def delete
      begin
        FileUtils.rm_f(cache_file) if File.exist?(cache_file)
      rescue => e
        puts "Failed to remove #{cache_file}, got #{e.class.name} #{e.message}"
      end
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
