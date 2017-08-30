if ENV['TEST_KITCHEN'] || defined?(::ChefSpec)
  module ChefVaultTestPatch
    def chef_vault_item(bag, id)
      if ::Chef.node.key?('chef_secrets') && ::Chef.node['chef_secrets'].key?(bag) && ::Chef.node['chef_secrets'][bag].key?(id)
        ::Chef::Log.warn "[Chef-Secrets] Chef vault item '#{bag}/#{id}' stubbed by test attributes"
        return ::Chef.node['chef_secrets'][bag][id]
      end

      super
    rescue
      ::Chef::Log.warn "You can stub this vault item for your tests by setting the attribute chef_secrets.#{bag}.#{id}!"

      raise
    end
  end

  ::Chef::Log.warn '[Chef-Secrets] Monkey patching chef_vault_item for tests'
  ::ChefVaultCookbook.prepend(::ChefVaultTestPatch)
  # Re-include ChefVaultcookbook module in Chef classes to get the update
  [::Chef::Node, ::Chef::Recipe, ::Chef::Resource, ::Chef::Provider].each { |klass| klass.send(:include, ::ChefVaultCookbook) }
end
