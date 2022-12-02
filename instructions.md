1. back up your data!
2. check you have enough disk space: `curl -L https://raw.githubusercontent.com/alxndrsn/odk-central/upgrade-postgres/check-available-space | bash`
2. create file `allow-postgres-database-version-update` in the central directory
3. follow traditional instructions at https://docs.getodk.org/central-upgrade/ (but instead of checking out the latest `master` branch, checkout the `upgrade-postgres` branch from https://github.com/alxndrsn/odk-central/tree/upgrade-postgres)
