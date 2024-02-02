resource_name :osl_mattermost
provides :osl_mattermost
unified_mode true

default_action :create

property :domain, String, name_property: true
property :edition, String, default: 'team'
property :mmctl_version, String, default: '8.1.9'
property :timezone, String, default: 'UTC'
property :version, String, default: '8.1'

action :create do
  include_recipe 'osl-git'
  include_recipe 'osl-docker'
  include_recipe 'osl-nginx'
  include_recipe 'osl-acme'

  acme_selfsigned new_resource.domain do
    crt '/etc/pki/tls/mattermost.crt'
    key '/etc/pki/tls/mattermost.key'
    notifies :restart, 'nginx_service[osuosl]', :immediately
  end

  cookbook_file '/etc/nginx/conf.d/mattermost.conf' do
    source 'nginx.conf.erb'
    cookbook 'osl-mattermost'
    notifies :restart, 'nginx_service[osuosl]', :immediately
  end

  directory '/var/www/acme' do
    recursive true
  end

  acme_certificate new_resource.domain do
    crt '/etc/pki/tls/mattermost.crt'
    key '/etc/pki/tls/mattermost.key'
    wwwroot '/var/www/acme'
    notifies :restart, 'nginx_service[osuosl]', :immediately
  end

  package %w(rsync tar)

  ark 'mmctl' do
    url "https://releases.mattermost.com/#{new_resource.mmctl_version}/mattermost-#{new_resource.mmctl_version}-linux-amd64.tar.gz"
    path '/opt/mattermost'
    creates 'mattermost/bin/mmctl'
    action :cherry_pick
  end

  link '/usr/local/bin/mmctl' do
    to '/opt/mattermost/bin/mmctl'
  end

  git '/var/lib/mattermost' do
    repository 'https://github.com/mattermost/docker'
    notifies :rebuild, 'osl_dockercompose[mattermost]'
  end

  directory '/var/lib/mattermost/volumes/app/mattermost' do
    owner 2000
    group 2000
    recursive true
  end

  %w(
    bleve-indexes
    client
    client/plugins
    config
    data
    logs
    plugins
  ).each do |d|
    directory "/var/lib/mattermost/volumes/app/mattermost/#{d}" do
      owner 2000
      group 2000
      recursive true
    end
  end

  template '/var/lib/mattermost/.env' do
    source 'env.erb'
    cookbook 'osl-mattermost'
    variables(
      edition: new_resource.edition,
      domain: new_resource.domain,
      timezone: new_resource.timezone,
      version: new_resource.version
    )
    notifies :rebuild, 'osl_dockercompose[mattermost]'
    notifies :restart, 'osl_dockercompose[mattermost]'
  end

  cookbook_file '/usr/local/libexec/mattermost-backup.sh' do
    cookbook 'osl-mattermost'
    mode '0755'
  end

  cron 'mattermost-backup' do
    time :daily
    command '/usr/local/libexec/mattermost-backup.sh'
  end

  osl_dockercompose 'mattermost' do
    directory '/var/lib/mattermost'
    config %w(docker-compose.yml docker-compose.without-nginx.yml)
  end
end
