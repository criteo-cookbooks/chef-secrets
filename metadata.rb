name             'chef-secrets'
maintainer       'SRE Core'
maintainer_email 'sre-core@criteo.com'
license          'All rights reserved'
description      'Installs/Configures chef-vault with helpers'
long_description 'Installs/Configures chef-vault with helpers'
version          '0.5.0'
source_url       'https://github.com/criteo-cookbooks/chef-secrets'
issues_url       'https://github.com/criteo-cookbooks/chef-secrets/issues'

depends 'chef-vault', '~> 2.1' # cookbook chef-vault 3.0.0 breaks our behavior for now

