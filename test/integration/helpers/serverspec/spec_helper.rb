require 'serverspec'

if /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
  set :backend, :cmd
  set :os, family: 'windows'
  # The GEM_PATH is set to ServerSpec gems, but knife needs Chef gems
  # The first run doesn't have C:\opscode\bin in the %PATH%, using full path for knife
  KNIFE = [
    '$env:GEM_PATH="',
    ::File.join('C:', 'opscode', 'chef', 'embedded', 'lib', 'ruby', 'gems', '2.3.0'),
    '"; ',
    ::File.join('C:', 'opscode', 'chef', 'bin', 'knife.bat'),
  ].join.freeze

  # C:/opscode/chef/embedded/lib/ruby/gems/2.3.0\"; #{::File.join('C:', 'opscode', 'chef', 'bin', 'knife.bat')}".freeze
else
  set :backend, :exec
  KNIFE = 'knife'.freeze
end
