# Setting up Renovate on a new repo

## Preparation

### Remove dependabot config

Remove any `dependabot.yml` file.

### Python dependencies

Note: currently Renovate doesn't fully respect the minimumReleaseAge with uv. This applies to:
- lockfileMaintenance
- bump / in-range-only range strategies

This means that, for now, we need to use the `widen` strategy for uv, and allow Renovate to expand the ranges in the `pyproject.toml`

Update all dependencies in the `pyproject.toml` to set ranges with upper limits
(Set to foo<=[current locked version]). Renovate needs this in order to apply version updates. Without any pins or ranges, it will consider the current locked version to satisfy the version constraints.

Remove any `exclude-newer` setting in `pyproject.toml`.

### JS dependencies

We use the `in-range-only` strategy for JS dependencies.

Ensure all dependencies in `package.json` are set to ranges with lower bounds. If any
dependency needs to be pinned to a specific version, it can be set with an equality or
upper bound. Renovate will not change the `package.json` ranges, and will only update
the locked versions if they meet the constraints set in `package.json`

### Docker image versions

Renovate will pin any docker image versions set in a Dockerfile to digests and keep them updated. Check if your repo uses a docker/.env file that sets image versions as an environment variables that are intended to override the default in the Dockerfile. If it does, remove them. Image versions should always be set in the Dockerfile itself.

### UV mirror

If required, add a `just uvmirror` recipe ([example.](https://github.com/opensafely-core/job-runner/blob/3d409e7c8849ea1a7f80594518e230142783ed58/justfile#L64))

If it’s there, drop the `.txt` extension from `requirements.uvmirror`.txt and update the `just uvmirror` recipe.

Add a Github action to update the uvmirror file ([example](https://github.com/opensafely-core/job-runner/blob/3d409e7c8849ea1a7f80594518e230142783ed58/.github/workflows/uvmirror-update.yml)). If there is already an action to check the uvmirror file, remove it. 

### Configure dependabot for the repo (needs bennett-admins)
Although we’re replacing dependabot for updates, Renovate uses dependabot alerts for security updates, so we still need it configured.

- Go to repo settings
- Select "Advanced Security" in the sidebar
- Enable the "Dependency graph"
- Enable "Dependabot alerts"
- Disable “Dependabot security updates” (otherwise dependabot will also open PRs for the - security alerts - we only want the Renovate ones)

### Adding Renovate (needs bennett-admins)

Add the Renovate app to the org (if necessary) and add the repo to the Renovate configuration:
- Go to https://github.com/apps/renovate, select Configure and install to the relevant org if necessary (if it’s already added, there will be a link to configure it)
- Select to add it just for the specific org (or if the app is already added, select configure, and scroll down to “Repository access“ and add the repo you’re setting up. This sends a request to the Bennett admins, who will have to approve it.

If it’s the first time installing to this org:
- Select product - Renovate only
- Select mode - Scan and Alert
- scroll down to the "Permissions" section and make sure that read access to "Dependabot alerts" is mentioned

After it sets things up, the Renovate app will ask for permissions for your GitHub account. After you grant it permission, it will redirect to the Mend developer platform (developer.mend.io) and ask you to sign in (the credentials will be pre-filled for you). 

Renovate adds a basic config file called `renovate.json` and creates a “configure renovate PR”.

## The Configure Renovate PR:
- Shows you the package files it’s detected
- Summarises the configuration
- Tells you about the update PRs it will create if you merge this one

## Configuration
Update the Configure Renovate PR with new config. The PR description will change and tell you what will happen now.

NOTE: renamed to renovate.json5 if you want to include comments.

To use just the presets from this repo, the `renovate.json5` only needs to contain:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>bennettoxford/renovate-config:default.json5",
    "github>bennettoxford/renovate-config:disable-uv-lockfilemaintenance.json5",
  ]
}
```

Add additional rules after this to customise for the repo. For example, to change the
schedule from the default early Wednesday morning, and prevent updates to pytest, change
the `renovate.json5` to:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>bennettoxford/renovate-config:default.json5",
    "github>bennettoxford/renovate-config:disable-uv-lockfilemaintenance.json5",
  ],
  // Run early Monday morning
  "schedule": ["* 0-3 * * MON"],
  "packageRules": [
    // pin pytest
    {
      "matchManagers": ["pep621"],
      "matchDepNames": ["pytest"],
      "allowedVersions": "<9.2.0"
    }
  ]
}
```

Also see [Renovate configuration docs](https://docs.renovatebot.com/configuration-options/).

If the repo has a justfile, add `just check-renovate-config` and `just renovate-dry-run` just recipes. See job-runner's [justfile](https://github.com/opensafely-core/job-runner/blob/3d409e7c8849ea1a7f80594518e230142783ed58/justfile#L240) for examples.

`just renovate-dry-run` runs renovate on your local repo, with the current renovate config and package versions, and shows what version updates renovate would make.

If you push an invalid config, the PR will change and tell you that.
You can look at the logs (linked in the PR) to see what went wrong.

## Workarounds for uv lockfile updaes

The [default config](default.json5) includes `lockFileMaintenance`. We want lockFileMainentance for updating transitive dependencies (Renovate’s main package managers will only update direct dependencies, by design). However, for `uv`, it doesn’t currently respect the minimumReleaseAge, so most repos will want to also use the
[disable-uv-lockfilemaintenance](disable-uv-lockfilemaintenance.json5) preset to disable
it for `uv`.

Instead, we need to reuse the [update-dependences action](https://github.com/opensafely-core/job-runner/blob/3d409e7c8849ea1a7f80594518e230142783ed58/.github/workflows/update-dependencies.yml) to do the same thing. This also requires an upgrade-all/update-dependencies [just recipe](https://github.com/opensafely-core/job-runner/blob/3d409e7c8849ea1a7f80594518e230142783ed58/justfile#L72), that runs with a “7 days ago” cooldown. Note that it’s important that `devenv` (or whatever recipe your repo has that runs `uv sync` runs **after** `upgrade-all`; this will remove the excludes-newer timestamps written into the `uv.lock`. (If you leave the timestamps in the uv.lock, the next developer to work on the repo will find that the uv.lock file gets mysteriously updated.)

## Enable Renovate

Once all the config updates etc are done, merge the configure renovate PR to enable Renovate. 

## Dependency Dashboard

Renovate creates an issue in the repo which summarises all the updates and lets you run immediately or trigger reruns.

If you’ve set schedules for updates, it won’t create PRs yet, but the dashboard will tell you want’s pending.

(Note: you can turn off the dependency dashboard issue in the config if you want; the summary and rerun options are available from the Developer dashboard too. If you keep the issue option, you probably want to pin the issue in the repo.)

## Developer Dashboard

<https://developer.mend.io>

Shows each Renovate run and lets you view logs. It also shows the same info as the dependency dashboard issue.
