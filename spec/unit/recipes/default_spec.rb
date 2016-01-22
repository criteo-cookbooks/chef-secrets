#
# Cookbook Name:: chef-secrets
# Spec:: default
#
# Copyright (c) 2016 Criteo, All Rights Reserved.

require 'spec_helper'

describe 'chef-secrets::default' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new
      runner.node.set['cookbook']['user'] = 'plaintext'
      runner.node.chef_secret_attribute_set(%w(cookbook pass), 'secret')
      runner.node.secret['cookbook']['sugar'] = 'value'
      runner.node.chef_secret_attribute_clear(%w(cookbook pass))
      runner.node.chef_secret_attribute_clear(%w(cookbook sugar))
      runner.converge(described_recipe)
    end

    it 'converges without errors' do
      expect { chef_run }.to_not raise_error
    end

    it 'contains the default attribute' do
      expect(chef_run.node['cookbook']['user']).to eq('plaintext')
    end

    it 'has memorised the attributes set with a secret' do
      expect(
        chef_run.run_context.node.instance_variable_get('@chef_secret_attributes')
      ).to eq([%w(cookbook pass), %w(cookbook sugar)])
    end

    it 'has cleared the attribute with a secret' do
      expect(chef_run.node['cookbook']['pass']).to eq('SECRET')
    end

    it 'works with syntax sugar' do
      expect(chef_run.node['cookbook']['sugar']).to eq('SECRET')
    end

    # Note:
    # The ChefSpec::ServerRunner fails with a "stack level too deep" error,
    # so we can't test the save method in ChefSpec :(
  end
end
