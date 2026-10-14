# Nearhost presets

The official preset registry for [Nearhost](https://nearhost.dev).

A preset is a data file that teaches Nearhost about one framework or tool: which ports it publishes, what to call them, and what to check in its config. Presets read project files and nothing else. They never run commands.

## Presets

| Preset | Enable as | Applies when |
|---|---|---|
| Docker Compose | `nearhost/compose` | The project has a Compose file |
| Laravel | `nearhost/laravel` | The project has an `artisan` file |
| Laravel Sail | `nearhost/sail` | The Compose file mentions `laravel/sail`, `image: sail-` or `LARAVEL_SAIL` |
| Vite | `nearhost/vite` | A Vite config file exists, or `package.json` depends on `vite` |

## Adding a preset

1. Write `presets/<name>.yaml`. `nearhost preset validate presets/<name>.yaml` reports every problem in it.
2. Add fixtures. A fixture is a directory under `fixtures/` holding sample project files and an `expected.yaml` that names the presets to enable and lists the routes and advisories they should produce. Name presets there without the `nearhost/` prefix.
3. Run `make check`. It uses the `nearhost` on your `PATH`. Pass `NEARHOST=/path/to/nearhost` to use another build, or run `make install-nearhost` to install the version CI uses.

## Licence

MIT
