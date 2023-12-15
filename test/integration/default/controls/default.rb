control 'default' do
  %w(
    80
    443
  ).each do |p|
    describe port p do
      it { should be_listening }
      its('addresses') { should eq %w(0.0.0.0 ::) }
      its('processes') { should eq %w(nginx) }
    end
  end

  describe http(
    'http://localhost',
    headers: { 'Host' => 'mm.example.org' }
  ) do
    its('status') { should cmp 301 }
    its('headers.location') { should cmp 'https://mm.example.org/' }
  end

  describe http(
    'https://localhost',
    headers: { 'Host' => 'mm.example.org' },
    ssl_verify: false
  ) do
    its('status') { should cmp 200 }
  end

  describe json(
    content: http(
      'https://localhost/api/v4/system/ping',
      headers: { 'Host' => 'mm.example.org' },
      ssl_verify: false
    ).body
  ) do
    its('status') { should cmp 'OK' }
  end

  describe docker_container 'mattermost-mattermost-1' do
    it { should be_running }
    its('image') { should eq 'mattermost/mattermost-team-edition:8.1' }
  end

  describe docker_container 'mattermost-postgres-1' do
    it { should be_running }
    its('image') { should eq 'postgres:13-alpine' }
  end

  describe command 'echo | openssl s_client -connect 127.0.0.1:443 -servername mm.example.org 2>/dev/null' do
    its('stdout') { should match(/CN ?= ?mm.example.org/) }
    its('stdout') { should match(/CN ?= ?Pebble Intermediate CA/) }
  end

  describe file '/etc/pki/tls/mattermost.crt' do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('content') { should match /-----BEGIN CERTIFICATE-----/ }
  end

  describe file '/etc/pki/tls/mattermost.key' do
    it { should exist }
    its('mode') { should cmp '0400' }
    its('content') { should match /-----BEGIN RSA PRIVATE KEY-----/ }
  end

  describe directory '/var/www/acme' do
    it { should exist }
  end

  %w(rsync tar).each do |p|
    describe package p do
      it { should be_installed }
    end
  end

  describe file '/usr/local/bin/mmctl' do
    its('link_path') { should eq '/opt/mattermost/bin/mmctl' }
  end

  describe command '/usr/local/bin/mmctl version' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Version:\s+v8.1.7/ }
  end

  describe directory '/var/lib/mattermost/volumes/app/mattermost' do
    its('uid') { should eq 2000 }
    its('gid') { should eq 2000 }
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
    describe directory "/var/lib/mattermost/volumes/app/mattermost/#{d}" do
      its('uid') { should eq 2000 }
      its('gid') { should eq 2000 }
    end
  end

  describe file '/var/lib/mattermost/.env' do
    it { should exist }
    its('content') { should match /^MATTERMOST_IMAGE=mattermost-team-edition$/ }
    its('content') { should match /^MATTERMOST_IMAGE_TAG=8.1$/ }
    its('content') { should match /^DOMAIN=mm.example.org$/ }
    its('content') { should match /^TZ=UTC$/ }
  end

  describe file '/usr/local/libexec/mattermost-backup.sh' do
    it { should exist }
    its('mode') { should cmp '0755' }
  end

  describe command '/usr/local/libexec/mattermost-backup.sh' do
    its('exit_status') { should eq 0 }
    its('stdout') { should eq '' }
    its('stderr') { should eq '' }
  end

  describe cron 'root' do
    it { should have_entry '@daily /usr/local/libexec/mattermost-backup.sh' }
  end
end
