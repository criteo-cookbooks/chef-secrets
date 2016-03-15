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

gem 'chef-vault'

group :ec2 do
  gem 'kitchen'
  gem 'kitchen-ec2', :git => 'https://github.com/criteo-forks/kitchen-ec2.git', :branch => 'criteo'
  gem 'winrm',      '~> 1.6'
  gem 'winrm-fs',   '~> 0.3'
end
