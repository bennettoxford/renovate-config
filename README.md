# Shared Renovate presets

This repository provides three shareable Renovate presets:

- `default.json`: shared update policy
- `disable-uv-lockfilemaintenance.json`: optional override that disables PEP 621 lockfile maintenance.

## Use the global preset

```json
{
  "extends": ["github>bennettoxford/renovate-config"]
}
```

## Opt in to the disable-uv-lockfile-maintenance preset

Extend both presets:

```json
{
  "extends": [
    "github>OWNER/renovate-config",
    "github>OWNER/renovate-config:disable-uv-lockfilemaintenance.json"
  ]
}
```

## Overriding global configuration

Put local configuration after the presets if a repository needs to override a shared setting.

## Global config settings

The global config extends the [Renovate recommended config](https://docs.renovatebot.com/presets-config/#configrecommended), plus:

- [Pins GitHub Actions to semver digests](https://docs.renovatebot.com/presets-helpers/#helperspingithubactiondigests)
- [Pins Docker images to digests](https://docs.renovatebot.com/presets-docker/#dockerpindigests)
- [Reports on abandoned packages](https://docs.renovatebot.com/presets-abandonments/)
- [Uses a 3 day cooldown for npm security updates](https://docs.renovatebot.com/presets-security/
- [Adds badges to PRs](https://docs.renovatebot.com/presets-mergeConfidence/#mergeconfidenceall-badges)
- [Groups all updates in a single group](https://docs.renovatebot.com/presets-group/)
- Disables PR and branch limits
- Add the "dependencies" label to all Renovate PRs
- Adds a custom manager to update versions in justfiles marked with a Renovate comment
- Enables lockfile maintenance for all packages
    - use the disable-uv-lockfilemaintenance preset to turn it off for uv
- Uses an early Wednesday morning schedule for all updates
    - use a local `{"schedule": ["..."]}` setting to override
- Uses a 7 day cooldown for all non-security updates
- Disables updates for:
    - python versions
    - node versions
    - github-runners
- Adds specific labels for js, python, actions, docker and security updates
- Sets the range strategy for js to `in-range-only` and for python to `widen`
- Sets minimumReleaseAgeBehaviour to `timestamp-optional` for GHA and docker, as not all datasources provide timestamps; without this, updates get stuck in the Pending state forever.
- Disables the cooldown for our own setup-action GHA

## JS/Python range strategies

Currently Renovate doesn't fully respect the minimumReleaseAge with uv. This applies to:
- lockfileMaintenance
- bump / in-range-only range strategies

As a result, we disable lockfile maintenance for uv, and use our update-dependencies-action instead, and we use the `widen` strategy for regular updates. This means that repos using uv need to use upper-bound ranges in their `pyproject.toml` (`ruff<=0.17` etc). If you need to pin a specific dependency, you will need to add a rule in the repo's local config, e.g.

```json
"packageRules": [
    {
      "matchManagers": ["pep621"],
      "matchDepNames": ["pytest"],
      "allowedVersions": "<9.2.0"
    }
]
```

For JS dependencies, minimumReleaseAge works as expected. We use the `in-range-only` range strategy so Renovate will not modify the ranges in `package.json`, and will only update versions that satisfy the bounds. Set ranges with lower bounds only if you want to get all updates. Set an upper bound to pin a dependency.


## Custom justfile tooling updates

The custom manager allows justfile tooling to be kept updated, by annotating versions with a Renovate comment.

e.g. in a justfile, define a version with a preceding Renovate comment:
```
# renovate: datasource=docker depName=kjanat/actionlint versioning=docker
actionlint_version := "1.17.0@sha256:d484cccadf56b6a356466ade9af4c8e05c5dce1badaf0a9ecd0d7639d68d9c92"
```

Using digests for docker images are recommended but not required. To update by version only:
```
# renovate: datasource=docker depName=kjanat/actionlint versioning=docker
actionlint_version := "1.17.0"
```

Use the version in your just recipes, e.g.
```
lint-actions:
    docker run ... kjanat/actionlint:{{ actionlint_version }}
```
