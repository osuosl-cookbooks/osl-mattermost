require_relative '../../spec_helper'

describe 'mattermost_test::default' do
  platform 'almalinux'
  cached(:subject) { chef_run }
  step_into :osl_mattermost

  before do
    stub_data_bag_item('nginx', 'dhparam').and_return(
      'id' => 'dhparam',
      'key' => 'dh param key'
    )
  end

  %w(
    osl-acme
    osl-docker
    osl-git
    osl-nginx
  ).each do |r|
    it { is_expected.to include_recipe r }
  end

  it do
    is_expected.to create_acme_selfsigned('mm.example.org').with(
      crt: '/etc/pki/tls/mattermost.crt',
      key: '/etc/pki/tls/mattermost.key'
    )
  end

  it { expect(chef_run.acme_selfsigned('mm.example.org')).to notify('nginx_service[osuosl]').to(:restart).immediately }

  it do
    is_expected.to create_cookbook_file('/etc/nginx/conf.d/mattermost.conf').with(
      source: 'nginx.conf.erb',
      cookbook: 'osl-mattermost'
    )
  end

  it do
    expect(chef_run.cookbook_file('/etc/nginx/conf.d/mattermost.conf')).to \
      notify('nginx_service[osuosl]').to(:restart).immediately
  end

  it { is_expected.to create_directory('/var/www/acme').with(recursive: true) }

  it do
    is_expected.to create_acme_certificate('mm.example.org').with(
      crt: '/etc/pki/tls/mattermost.crt',
      key: '/etc/pki/tls/mattermost.key',
      wwwroot: '/var/www/acme'
    )
  end

  it do
    expect(chef_run.acme_certificate('mm.example.org')).to \
      notify('nginx_service[osuosl]').to(:restart).immediately
  end

  it { is_expected.to install_package %w(rsync tar) }

  it do
    is_expected.to cherry_pick_ark('mmctl').with(
      url: 'https://releases.mattermost.com/10.5.3/mattermost-10.5.3-linux-amd64.tar.gz',
      path: '/opt/mattermost',
      creates: 'mattermost/bin/mmctl'
    )
  end

  it { expect(chef_run.link('/usr/local/bin/mmctl')).to link_to('/opt/mattermost/bin/mmctl') }

  it do
    is_expected.to sync_git('/var/lib/mattermost').with(
      repository: 'https://github.com/mattermost/docker'
    )
  end

  it { expect(chef_run.git('/var/lib/mattermost')).to notify('osl_dockercompose[mattermost]').to(:rebuild) }

  it do
    is_expected.to create_directory('/var/lib/mattermost/volumes/app/mattermost').with(
      owner: 2000,
      group: 2000,
      recursive: true
    )
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
    it do
      is_expected.to create_directory("/var/lib/mattermost/volumes/app/mattermost/#{d}").with(
        owner: 2000,
        group: 2000,
        recursive: true
      )
    end
  end

  it { is_expected.to pull_docker_image('mattermost/mattermost-team-edition').with(tag: '10.5') }
  it { is_expected.to pull_docker_image('postgres').with(tag: '13-alpine') }
  %w(
    mattermost/mattermost-team-edition
    postgres
  ).each do |i|
    it { expect(chef_run.docker_image(i)).to notify('osl_dockercompose[mattermost]').to(:rebuild) }
    it { expect(chef_run.docker_image(i)).to notify('osl_dockercompose[mattermost]').to(:restart) }
  end

  it do
    is_expected.to create_template('/var/lib/mattermost/.env').with(
      source: 'env.erb',
      cookbook: 'osl-mattermost',
      variables: {
        edition: 'team',
        domain: 'mm.example.org',
        timezone: 'UTC',
        version: '10.5',
      }
    )
  end

  it do
    is_expected.to create_cookbook_file('/usr/local/libexec/mattermost-backup.sh').with(
      cookbook: 'osl-mattermost',
      mode: '0755'
    )
  end

  it do
    is_expected.to create_cron('mattermost-backup').with(
      time: :daily,
      command: '/usr/local/libexec/mattermost-backup.sh'
    )
  end

  it { expect(chef_run.template('/var/lib/mattermost/.env')).to notify('osl_dockercompose[mattermost]').to(:rebuild) }
  it { expect(chef_run.template('/var/lib/mattermost/.env')).to notify('osl_dockercompose[mattermost]').to(:restart) }
end
