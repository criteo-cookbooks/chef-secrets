require 'spec_helper'

require_relative '../../libraries/helpers'

describe ChefVaultCookbook do
  describe '#chef_vault_item_or_default' do
    let(:dummy_class) { Class.new { include ChefVaultCookbook } }

    it 'fails with no item in ChefVault nor default' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(false)
      expect { dummy_class.new.chef_vault_item_or_default('bag', 'id') }.to raise_error(RuntimeError)
    end

    it 'returns a ChefVault item if it exists, without a default' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(true)
      allow(ChefVault::Item).to receive(:load).with('bag', 'id').and_return('secret')
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id')).to eq('secret')
    end

    it 'returns a ChefVault item if it exists, with a default' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(true)
      allow(ChefVault::Item).to receive(:load).with('bag', 'id').and_return('secret')
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('secret')
    end

    it 'raises an error if there is a problem with databag retrieval' do
      response = Net::HTTPUnprocessableEntity.new('1.1', '418', "I'm a teapot")
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id')
        .and_raise(Net::HTTPServerException.new('I cannot make coffee!', response))
      expect { dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default') }
        .to raise_error(Net::HTTPServerException)
    end

    it 'returns defined default if the vault databag does not exist (Rest mode)' do
      response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id')
        .and_raise(Net::HTTPServerException.new('Not Found', response))
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('default')
      # chef-vault >= 4.0.5
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id3').and_raise(ChefVault::Exceptions::ItemNotFound)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id3', 'default3')).to eq('default3')
    end

    it 'returns defined default if the vault databag does not exist (Solo mode)' do
      # Missing databag Item
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id1').and_raise(Chef::Exceptions::InvalidDataBagItemID)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id1', 'default1')).to eq('default1')
      # Missing databag
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id2').and_raise(Chef::Exceptions::InvalidDataBagPath)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id2', 'default2')).to eq('default2')
    end

    it 'returns defined default if the item cannot be decrypted' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(true)
      allow(ChefVault::Item).to receive(:load).with('bag', 'id')
        .and_raise(ChefVault::Exceptions::SecretDecryption)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('default')
    end
  end
end
