name             'chef-secrets'
maintainer       'SRE Core'
maintainer_email 'sre-core@criteo.com'
license          'All rights reserved'
description      'Installs/Configures chef-vault with helpers'
long_description 'Installs/Configures chef-vault with helpers'
version          '2.0.0'
source_url       'https://github.com/criteo-cookbooks/chef-secrets' if defined?(source_url)
issues_url       'https://github.com/criteo-cookbooks/chef-secrets/issues' if defined?(issues_url)

chef_version '>= 14.0' if respond_to?(:chef_version)

depends 'chef-vault', '~> 2.1' # cookbook chef-vault 3.0.0 breaks our behavior for now
gem 'chef-vault', '4.0.12'
