# Nearhost presets

The official preset registry for [Nearhost](https://nearhost.dev).

A preset is a data file that teaches Nearhost about one framework or tool: which ports it publishes, what to call them, and what to check in its config. Presets read project files and nothing else. They never run commands.

## Using these presets

Nearhost trusts no registry until you add one:

```sh
nearhost preset registry add nearhost/presets
```

After that, `nearhost add` offers each preset that suits the project. You can also enable one yourself:

```sh
nearhost preset enable nearhost/vite
```

## Presets

| Preset | Enable as | Applies when |
|---|---|---|
| Docker Compose | `nearhost/compose` | The project has a Compose file |
| Laravel | `nearhost/laravel` | The project has an `artisan` file |
| Laravel Sail | `nearhost/sail` | The Compose file mentions `laravel/sail`, a `sail-` image (quoted or not) or `LARAVEL_SAIL` |
| Vite | `nearhost/vite` | A Vite config file exists, or `package.json` depends on `vite` |

## Adding a preset

1. Write `presets/<name>.yaml`. `nearhost preset validate presets/<name>.yaml` reports every problem in it.
2. Add fixtures. A fixture is a directory under `fixtures/` holding sample project files and an `expected.yaml` that names the presets to enable and lists the routes and advisories they should produce. Name presets there without the `nearhost/` prefix.
3. Run `make check`. It uses the `nearhost` on your `PATH`. To check against the version CI uses, run `make install-nearhost`, which installs it into `$(go env GOPATH)/bin`, then `make check NEARHOST="$(go env GOPATH)/bin/nearhost"`.
4. Leave `index.yaml` alone. After a merge that changes a preset, CI opens a pull request, `chore: rebuild the index`, with the new index. Merging it publishes the change.

## Licence

MIT
