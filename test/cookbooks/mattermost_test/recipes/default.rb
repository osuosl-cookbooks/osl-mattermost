osl_postgresql_test 'mattermost' do
  username 'mattermost'
  password 'mattermost'
end

osl_mattermost 'mm.example.org' do
  db_host node['ipaddress']
  db_user 'mattermost'
  db_password 'mattermost'
  db_name 'mattermost'
end
