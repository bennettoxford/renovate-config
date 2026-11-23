import 'justfile.base'

set dotenv-load := true
set positional-arguments := true

# List available commands
default:
    @{{ just_executable() }} --list --unsorted

lint-actions:
    {{ docker_run_safe }} -v $(pwd):/repo:ro --workdir /repo kjanat/actionlint:{{ actionlint_version }} -color

# Run the various dev checks but does not change any files
check:
    just lint-actions
    for file in *.json5; do just check-renovate-config "$file" || exit; done

# Fix any automatically fixable linting or formatting errors
fix:
    just --fmt --unstable

check-renovate-config PRESET_FILE:
    {{ docker_run_safe }} -v $(pwd):/repo:ro --workdir /repo renovate/renovate:{{ renovate_version }} renovate-config-validator {{ PRESET_FILE }}
