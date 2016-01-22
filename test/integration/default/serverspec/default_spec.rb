require 'spec_helper'

describe 'chef_vault_secret resource' do
  # Set up the paths to the private key and client.rb
  key = ::File.join(::File.expand_path('..', ENV['BUSSER_ROOT']), 'kitchen', 'clients', 'hydroelectric.pem')
  cfg = ::File.join(::File.expand_path('..', ENV['BUSSER_ROOT']), 'kitchen', 'client.rb')

  describe command("#{KNIFE} vault show green clean-energy -z -u hydroelectric -k #{key} -c #{cfg}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("#{KNIFE} vault show green dirty-energy -z -u hydroelectric -k #{key} -c #{cfg}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("#{KNIFE} search node 'name:*' -a test-secrets.secret -z -c #{cfg}") do
    its(:stdout) { should contain 'test-secrets.secret' }
    its(:stdout) { should_not contain 'SecretPassword' }
  end
end
