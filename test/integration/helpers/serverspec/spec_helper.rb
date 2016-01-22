require 'serverspec'

if /cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM
  set :backend, :cmd
  set :os, family: 'windows'
  # The first run doesn't have C:\opscode\bin in the %PATH%
  KNIFE = ::File.join('C:', 'opscode', 'chef', 'bin', 'knife.bat')
else
  set :backend, :exec
  KNIFE = 'knife'
end
