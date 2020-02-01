source 'https://rubygems.org'

group :rake do
  gem 'rake'
end

group :lint do
  gem 'foodcritic'
end

group :unit do
  gem 'berkshelf'
  gem 'chefspec'
end

gem 'chef-vault', '= 4.0.1'

group :ec2 do
  gem 'kitchen'
  gem 'kitchen-ec2', git: 'https://github.com/criteo-forks/kitchen-ec2.git', branch: 'criteo'
  gem 'winrm'
  gem 'winrm-fs'
end
