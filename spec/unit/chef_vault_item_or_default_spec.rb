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

    it 'returns defined default if the ChefVault item does not exist' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(false)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('default')
    end

    it 'raises an error if there is a problem with databag retrieval' do
      response = Net::HTTPUnprocessableEntity.new('1.1', '418', "I'm a teapot")
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id')
        .and_raise(Net::HTTPServerException.new('I cannot make coffee!', response))
      expect { dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default') }
        .to raise_error(Net::HTTPServerException)
    end

    it 'returns defined default if the vault databag does not exist' do
      response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      allow(Chef::DataBagItem).to receive(:load).with('bag', 'id')
        .and_raise(Net::HTTPServerException.new('Not Found', response))
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('default')
    end

    it 'returns defined default if the item cannot be decrypted' do
      allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(true)
      allow(ChefVault::Item).to receive(:load).with('bag', 'id')
        .and_raise(ChefVault::Exceptions::SecretDecryption)
      expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default')).to eq('default')
    end

    describe 'caching mechanism' do
      context 'when value is recent enough' do
        it 'return cached value' do
          expect(ChefVault::Item).not_to receive(:vault?)
          expect(ChefVault::Item).not_to receive(:load)

          expect(File).to receive(:exist?).and_return(true)
          expect(File).to receive(:mtime).and_return(Time.now)
          expect(File).to receive(:read).and_return("cached_value".to_json)
          expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default', use_cache: true)).to eq('cached_value')
        end
      end

      context 'when value is very old' do
        it 'return cached value' do
          allow(ChefVault::Item).to receive(:vault?).with('bag', 'id').and_return(true)
          allow(ChefVault::Item).to receive(:load).with('bag', 'id').and_return('secret')

          expect(File).to receive(:exist?).and_return(true)
          expect(File).to receive(:mtime).and_return(Time.now - 86400)
          expect(dummy_class.new.chef_vault_item_or_default('bag', 'id', 'default', use_cache: true)).to eq('secret')
        end
      end
    end
  end
end
