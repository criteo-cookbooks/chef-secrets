name             'chef-secrets'
maintainer       'SRE Core'
maintainer_email 'sre-core@criteo.com'
license          'All rights reserved'
description      'Installs/Configures chef-vault with helpers'
long_description 'Installs/Configures chef-vault with helpers'
version          '0.6.4'
source_url       'https://github.com/criteo-cookbooks/chef-secrets' if defined?(source_url)
issues_url       'https://github.com/criteo-cookbooks/chef-secrets/issues' if defined?(issues_url)

depends 'chef-vault', '~> 2.1' # cookbook chef-vault 3.0.0 breaks our behavior for now
