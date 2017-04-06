name             'chef-secrets'
maintainer       'SRE Core'
maintainer_email 'sre-core@criteo.com'
license          'All rights reserved'
description      'Installs/Configures chef-vault with helpers'
long_description 'Installs/Configures chef-vault with helpers'
version          '0.3.0'
source_url       'https://github.com/criteo-cookbooks/chef-secrets'
issues_url       'https://github.com/criteo-cookbooks/chef-secrets/issues'

depends 'chef-vault'

gem 'chef-vault', '= 2.8.0'
