#!/usr/bin/env bash

# Set chef-vault library location
lib='ext/chef-vault/lib/chef-vault'
echo "Bundling chef-vault files from ${lib}."

# Enable ** for recursive match
shopt -s globstar

for i in $lib/**/*.rb; do
  sub="${i#$lib/}";
  new="chef-vault_${sub//\//_}";
  cp "$i" "libraries/$new"
done

# Removing version.rb
rm libraries/chef-vault_version.rb
