osl_postgresql_server 'mattermost' do
  version '16'
  access 'access'
  osl_only false
end

postgresql_user 'mattermost' do
  unencrypted_password 'mattermost'
  login true
end

postgresql_database 'mattermost' do
  owner 'mattermost'
end

osl_mattermost 'mm.example.org' do
  db_host node['ipaddress']
  db_user 'mattermost'
  db_password 'mattermost'
  db_name 'mattermost'
end
