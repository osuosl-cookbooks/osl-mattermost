include_recipe 'osl-nginx'

file '/etc/nginx/conf.d/test-kitchen.conf' do
  content 'server_names_hash_bucket_size 128;'
  notifies :reload, 'nginx_service[osuosl]', :immediately
end

osl_mattermost 'mm.example.org'
