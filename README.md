# ns8-windmill

Open source platform to build internal tools, workflows and scripts in Python, TypeScript, Go and other languages.

Module id: `windmill`. Images are pinned in `build-images.sh` and updated through reviewed changes.

## Install

```bash
add-module ghcr.io/geniusdynamics/windmill:latest 1
```

The command returns the instance id, for example `windmill1`. Use the id NS8 returns.

## Configure

```bash
api-cli run configure-module --agent module/windmill1 --data - <<'EOF'
{
  "host": "windmill.example.org",
  "http2https": true,
  "lets_encrypt": false
}
EOF
```

| Parameter | Required | Type | Description |
|---|---|---|---|
| `host` | yes | string | Host name for the application, like 'windmill.domain.org' |
| `lets_encrypt` | yes | boolean | Request a valid Let's Encrypt certificate. |
| `http2https` | yes | boolean | Redirect all the HTTP requests to HTTPS |

## Configuration output

`get-configuration` returns: `host`, `lets_encrypt`, `http2https`.

## Images

| Image | Version |
|---|---|
| `ghcr.io/windmill-labs/windmill` | `1.871.1` |
| `ghcr.io/windmill-labs/windmill-extra` | `1.871.1` |
| `ghcr.io/windmill-labs/caddy-l4` | `2.11.4-1` |
| `docker.io/postgres` | `18.7` |

Requires NS8 core `3.12.4-0` or newer.

## Network and access

- Reserves 1 TCP port(s) on the node. The web application is published through Traefik on the configured host name.
- Runs rootless.
- Declares these NS8 authorizations: `traefik@node:routeadm`.

## Backup

The following paths are included in the NS8 backup (`imageroot/etc/state-include.conf`):

- `state/passwords.env`
- `state/windmill.sql`

## Services

- `caddy-app.service`
- `db-app.service`
- `extra-app.service`
- `server-app.service`
- `windmill.service`
- `worker-app.service`
- `worker-native-app.service`

## Get the configuration

```bash
api-cli run get-configuration --agent module/windmill1
```

## Update and uninstall

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/geniusdynamics/windmill:latest","instances":["windmill1"],"force":true}'
remove-module --no-preserve windmill1
```

## Testing

Continuous integration:

- `Publish images` builds the module image on every push.
- `Test module` installs the image on a QEMU NS8 node and runs the Robot Framework suite in `tests/`. It runs after `Publish images` succeeds on `dev` and on `main`.
- `Build API JSON Schema docs` and the security scan run alongside.

The suite installs the module, configures a host name, checks that the web application answers through Traefik, takes UI screenshots and removes the module.

Run it locally with the NS8 standard infrastructure described in the [ns8-github-actions README](https://github.com/NethServer/ns8-github-actions/blob/v1/README.md#running-tests-locally).

## Open items

Found by the NS8 module standards check. These must be resolved before a stable release:

- README still has the template boilerplate
- floating or partial image tag, pin a full version: docker.io/postgres:18.6

## Upstream

Application documentation: https://www.windmill.dev/docs

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
