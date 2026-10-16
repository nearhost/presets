<a href="https://nearhost.dev"><img src="https://raw.githubusercontent.com/nearhost/.github/main/assets/header-presets.png" alt="Nearhost. Run it anywhere. Open it here. The official preset registry."></a>

# Nearhost presets

The official preset registry for [Nearhost](https://github.com/nearhost/nearhost): what it knows about Docker Compose, Laravel, Laravel Sail and Vite, kept as data you can read. Nearhost is a terminal app that opens a dev server running on one of your other machines at a local `https://myapp.test`, over the SSH config you already have.

```sh
nearhost preset registry add nearhost/presets
```

[Website](https://nearhost.dev) · [Docs](https://nearhost.dev/docs/getting-started/introduction/) · [Nearhost](https://github.com/nearhost/nearhost) · [Install Nearhost](https://nearhost.dev/docs/getting-started/install/)

On its own, Nearhost knows one thing about a project: the port variables in its `.env`. That is enough to serve any dev server at `https://<name>.test`, but it cannot know that `5173` is a Vite dev server that the browser must reach on `localhost`, or that a Compose file publishes the web app on container port 80.

That knowledge lives here, as presets. A preset is a short YAML file that tells Nearhost when it applies, which ports to propose and what to call them, and what to check in the project's config. Nearhost downloads a preset only after you trust this registry and agree to enable it.

## Why presets

- **Read-only data.** A preset reads files inside the project and proposes routes and advice. It cannot run a command, make a request or change a file. Its expressions are [CEL](https://cel.dev) with a cost limit, and its patterns are RE2, which runs in linear time.
- **Nothing until you say so.** A fresh Nearhost trusts no registry and makes no request for presets. You trust a registry once, and `nearhost add` still asks before enabling each preset it suggests.
- **Pinned and checked.** The index names a commit and a SHA-256 for every preset. Nearhost downloads the file at that commit and refuses it if the hash differs. An installed preset never changes until you run `nearhost preset update`.
- **Visible source.** Presets from a registry are named after it, as in `nearhost/vite`, so you know where each one came from, and two registries can offer the same name without clashing.
- **Tested against every build.** Each preset has fixtures: sample projects with the routes and advice they must produce. They run on every pull request here and on every pull request to Nearhost itself.
- **Yours to extend.** Any public GitHub repository laid out like this one is a registry. Publish your own presets and trust them the same way.

## The presets

| Preset | Turns on when | What it adds |
| --- | --- | --- |
| `nearhost/compose` | The project has a Compose file | A route for every TCP port the Compose file publishes, labelled with its service. A service on container port 80 becomes the web route. |
| `nearhost/laravel` | The project has an `artisan` file | Advice when `APP_URL` is not `https://<alias>`, since generated links use it. |
| `nearhost/sail` | The Compose file mentions `laravel/sail`, a `sail-` image (quoted or not) or `LARAVEL_SAIL` | Compose's published ports, with the Vite dev server forwarded to `localhost` through `VITE_PORT` so assets and hot reload load. Vite advice that fits a container: set `VITE_PORT` in `.env`. |
| `nearhost/vite` | A `vite.config.*` file exists, or `package.json` depends on `vite` | The dev server port from `server.port` as a route. Advice when the port is left at the default 5173, which other Vite projects also use, and when `server.allowedHosts` would reject the alias. |

Presets combine. On a Sail project with a Vite frontend, `sail`, `laravel` and `vite` all apply, and `sail` adjusts what `vite` would say for a server that runs in a container.

## Use them

Trust the registry. The first `nearhost add` at a terminal also offers to do this for you:

```sh
nearhost preset registry add nearhost/presets
```

From then on, `nearhost add` suggests the presets that suit a project and asks before enabling each one:

```text
$ cd /home/dev/code/myapp
$ nearhost add
This looks like a Docker Compose project. Enable nearhost/compose from nearhost/presets? [Y/n] y
This looks like a Vite project. Enable nearhost/vite from nearhost/presets? [Y/n] y
Routes found for myapp (local:/home/dev/code/myapp):
  PORT  ROLE    LABEL
  5173  ignore  Vite (vite.config)
  5432  ignore  db
  8080  web     app

Added myapp on local at https://myapp.test
Start it with `nearhost up`.
```

Without a terminal, `add` prints the `--preset` flag for each suggestion instead, and enables nothing.

Manage them directly with:

| Command | What it does |
| --- | --- |
| `nearhost preset list` | Show the enabled presets and where they came from, then what each registry offers |
| `nearhost preset enable nearhost/vite` | Download, check and enable a preset |
| `nearhost preset update` | Move enabled presets to the registry's current versions and say what changed |
| `nearhost preset disable nearhost/vite` | Stop using a preset. Its file is kept |
| `nearhost preset registry remove nearhost` | Stop trusting the registry, once none of its presets are enabled |

## How a preset reaches you

The registry is this repository's default branch. Nearhost reads `index.yaml` from it, which lists each preset's name, title, the expression that decides when it applies, and its SHA-256. The index also names `ref`, the last commit that changed `presets/`. Nearhost downloads each preset from `raw.githubusercontent.com` at that commit, so the URL cannot change under you, and it rejects any file whose bytes do not match the hash.

Leave `index.yaml` alone. After a merge that changes a preset, CI rebuilds it and opens a pull request, `chore: rebuild the index`. Merging that pull request publishes the change. Until then, Nearhost keeps serving the presets the current index names, whose files and hashes still match.

## Writing a preset

A preset is one file, `presets/<name>.yaml`, whose `name` matches the file name. This is the whole of `compose`:

```yaml
schema: 1
name: compose
title: Docker Compose
description: Routes for the published ports in compose.yaml
detect: compose != ""
compose: ports
```

A preset that reads a project's config scans it with facts, turns facts into routes and advice, and can label port variables. This is a shortened `vite`:

```yaml
schema: 1
name: vite
title: Vite
description: Finds the Vite dev server port and checks its host settings.
detect: file("vite.config.js", "vite.config.ts") || pkg("vite")

facts:
  port:
    scan: [vite.config.js, vite.config.ts]
    regex: '\bserver\s*:\s*\{[^}]*?\bport\s*:\s*(\d+)'
    as: int

routes:
  - id: vite-config-port
    when: facts.port > 0
    port: facts.port
    label: Vite (vite.config)
    web: fallback

advisories:
  - id: vite-default-port
    when: facts.port == 0
    message: Vite will use the default port 5173, which other Vite projects also use.
    snippet: "server: { port: {{ free_port(5173) }} }"
```

### Keys

| Key | Required | Meaning |
| --- | --- | --- |
| `schema` | yes | The preset format version, `1` |
| `name` | yes | Lowercase letters, digits and hyphens; the file name without `.yaml` |
| `title` | yes | The name shown in suggestions, such as `This looks like a Vite project` |
| `description` | no | One sentence for `preset list` |
| `detect` | yes | A CEL expression that is true when the preset applies |
| `after` | no | Presets that must run before this one when they apply |
| `compose` | no | `ports` asks Nearhost for the Compose file's published ports |
| `ports` | no | Port variables to label: `var`, `label`, `role` (`ignore` or `loopback`) and `web` (`preferred` or `fallback`) |
| `facts` | no | Values scanned from the first file in `scan` that exists, with an RE2 `regex` and an `as` type |
| `routes` | no | Routes computed from facts: `id`, `when`, `port`, `label`, `role` and `web` |
| `suppress` | no | Ids of routes and advisories from earlier presets to remove |
| `advisories` | no | Advice to show: `id`, `when`, `message` and `snippet`, where `{{ expr }}` is filled in |

A preset never sets the web role itself. It hints with `web: preferred` or `web: fallback`, and Nearhost chooses. A later preset replaces an earlier route or advisory by using the same `id`, or removes it with `suppress`. That is how `sail` changes Vite's advice without `vite` knowing Sail exists.

A fact's `as` is `int`, `string` or `quoted_list`, which read the first capture group, or `bool`, which says whether the pattern matched. When the file or the match is missing, the fact is `0`, `""`, `[]` or `false`.

### Expressions

| Name | Available in | Meaning |
| --- | --- | --- |
| `env` | everywhere | The merged values of `.env` and `.env.local` |
| `compose` | everywhere | The Compose file's text, or `""`; use `compose.contains("...")` |
| `file(a, b, ...)` | everywhere | Whether any of the named files exists |
| `pkg(name)` | everywhere | Whether `package.json` lists `name` in its dependencies or devDependencies |
| `facts` | routes, advisories | This preset's facts |
| `active(name)` | routes, advisories | Whether the named preset applies |
| `presets` | routes, advisories | The facts of each preset that ran earlier, by name |
| `alias` | advisories | The project's hostname, such as `myapp.test` |
| `free_port(n)` | advisories | The lowest port from `n` up that no enabled project forwards to `localhost` |
| `host_in(host, list)` | advisories | Whether `host` is in `list`, where an entry starting with `.` matches a domain suffix |

`detect` can use only the first four, because Nearhost evaluates it from the index before you install the preset. Inside a preset, a plain name such as `vite` always means the preset of that name from the same registry.

### Fixtures

Every preset needs fixtures. A fixture is a directory under `fixtures/` holding sample project files and an `expected.yaml`. This one is a Compose project with a Vite config that sets no port, while another project already forwards 5173:

```yaml
presets: [compose, vite]       # enable these, by plain name
alias: myapp.test              # optional; the default is <directory>.test
others:                        # optional; ports other projects forward to localhost
  - name: shop
    loopback: [5173]
routes:
  - port: 5432
    role: ignore
    label: db
  - port: 8080
    role: web
    label: app
advisories:
  - id: vite-default-port
    snippet: |                 # message and snippet are compared when given
      // vite.config.ts
      export default defineConfig({
        server: {
          port: 5174,
        },
      })
```

`nearhost preset test fixtures --presets presets` runs every fixture and prints each difference. Write the fixture first and watch it fail, then write the preset.

## Development

You need Git, Make and Go 1.26 or later, which is used only to install `nearhost`.

```sh
git clone https://github.com/nearhost/presets.git
cd presets
make install-nearhost                                  # the nearhost version CI uses
make check NEARHOST="$(go env GOPATH)/bin/nearhost"
```

| Target | What it does |
| --- | --- |
| `make check` | `validate`, then `test` |
| `make validate` | Check every preset and report every problem, not only the first |
| `make test` | Run every fixture |
| `make index` | Preview `index.yaml`. It refuses while `presets/` has uncommitted changes, because the index names a commit |
| `make install-nearhost` | Install `nearhost` at the commit in `NEARHOST_COMMIT` |

`make check` uses the `nearhost` on your `PATH` unless you pass `NEARHOST`. CI installs the version pinned in the `Makefile` and also tests the script that opens the index pull request (`bash scripts/test-index-pr.sh`). Raise `NEARHOST_COMMIT` when the preset format changes in Nearhost.

### Run your own registry

Any public GitHub repository with presets in `presets/` and an `index.yaml` on its default branch is a registry. Build the index with:

```sh
nearhost preset index presets --ref "$(git log -1 --format=%H -- presets)" > index.yaml
```

Copying this repository's `Makefile`, `scripts/` and `.github/workflows/ci.yml` gives you the same checks and the same index pull requests; the workflow needs a GitHub App that can open pull requests. Anyone can then trust your registry under an alias of their choosing:

```sh
nearhost preset registry add acme/nearhost-presets --as acme
nearhost preset enable acme/<name>
```

### Contributing

Open a pull request against `main` with the preset and its fixtures. Pull requests are squash merged and the title becomes the commit message, so write it as a [Conventional Commit](https://www.conventionalcommits.org/), such as `feat: add the <name> preset` or `fix(vite): read quoted keys in the vite config`. Leave `index.yaml` alone; CI opens the pull request that publishes your change once it is merged.

## Licence

[MIT](LICENSE)
