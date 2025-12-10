# osl-mattermost

Deploy and manage Mattermost instances

## Requirements

### Platforms

- AlmaLinux 8/9/10

### Cookbooks

- ark
- osl-acme
- osl-docker
- osl-git
- osl-nginx

## Attributes

## Resources

### `osl_mattermost`

Creates a Mattermost deployment backed by an external PostgreSQL database, using Docker Compose and nginx with ACME-provided TLS certificates.

**Properties**

- `domain` (name_property, String): FQDN for the site and TLS certs.
- `db_host` (String, required): PostgreSQL host.
- `db_user` (String, required): PostgreSQL user.
- `db_password` (String, required, sensitive): PostgreSQL password.
- `db_name` (String, required): PostgreSQL database name.
- `edition` (String, default: `team`): Mattermost edition (`team` or `enterprise`).
- `version` (String, default: `10.11`): Mattermost image tag.
- `mmctl_version` (String, default: `10.11.8`): `mmctl` CLI version to install.
- `timezone` (String, default: `UTC`): Container timezone.

## Recipes

- `default` — empty placeholder; use the `osl_mattermost` resource instead.

## Usage

```ruby
osl_mattermost 'chat.example.org' do
    db_host 'db.example.org'
    db_user 'mattermost'
    db_password 'supersecret'
    db_name 'mattermost'
    edition 'team'
    version '10.11'
    mmctl_version '10.11.8'
    timezone 'America/Los_Angeles'
end
```

The resource:

- Requests a Let's Encrypt certificate via `osl-acme` and configures nginx as a reverse proxy.
- Drops Docker Compose config and `.env` variables under `/var/lib/mattermost` and rebuilds the stack when they change.
- Installs `mmctl` to `/usr/local/bin`.

Ensure the referenced PostgreSQL database, user, and credentials already exist before convergence.

## Contributing

1. Fork the repository on Github
1. Create a named feature branch (like `username/add_component_x`)
1. Write tests for your change
1. Write your change
1. Run the tests, ensuring they all pass
1. Submit a Pull Request using Github

## License and Authors

- Author:: Oregon State University <chef@osuosl.org>

```text
Copyright:: 2023, Oregon State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
