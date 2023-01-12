1. back up your data!
2. check you have enough disk space: `curl -L https://raw.githubusercontent.com/alxndrsn/odk-central/upgrade-postgres/check-available-space | bash`
3. create file `allow-postgres-upgrade` in the central directory
4. follow traditional instructions at https://docs.getodk.org/central-upgrade/ (but instead of checking out the latest `master` branch, checkout the `upgrade-postgres` branch from https://github.com/alxndrsn/odk-central/tree/upgrade-postgres)
