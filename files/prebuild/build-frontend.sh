#!/bin/bash -eu
cd client
echo "#####################################################"
ls -al
echo "#####################################################"
ls -al node_modules || echo "node_modules not yet populated"
echo "#####################################################"
npm clean-install --no-audit --fund=false --update-notifier=false
npm run build
