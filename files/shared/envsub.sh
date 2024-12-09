#!/bin/bash -eu

# Safer implemention of envsubst.
#
# Significant differences:
#
#   * require curly brackets around values
#   * require uppercase
#   * throw error if value is not defined, instead of just using empty string
#
# mawk is the awk implementation common to the containers we need to run this
# run this script in, so we use it here explicitly.

mawk '{
  while(match($0, /\$\{[A-Z_][A-Z_0-9]*\}/) > 0) {
    k = substr($0, RSTART+2, RLENGTH-3);
    if(k in ENVIRON) {
      v = ENVIRON[k];
      gsub("\$\{" k "\}", v);
    } else {
      print "No env value found: ${" k "}";
      exit 1
    }
  }
  print $0
}'
