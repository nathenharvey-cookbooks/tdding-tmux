guard 'bundler' do
  watch('Gemfile')
end

guard 'rspec', spec_paths: ['cookbooks/*/spec', 'spec'] do
  watch(%r{spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')  { 'spec' }

  watch(%r{^cookbooks/[A-Za-z_\-]+/recipes/(.+)\.rb$}) { |m| "cookbooks/#{m[1]}/spec/#{m[2]}_spec.rb" }
  watch(%r{^cookbooks/([A-Za-z_\-]+)/(.+)(\..*)?$}) { |m| "cookbooks/#{m[1]}/spec/*.rb" }
end

