#!/bin/bash

group=$(groups $PAM_USER | grep -c admin)
uday=$(date +%u)

if [[ $group -eq 1 || $uday -gt 5 ]]; then
   exit 0
else
   exit 1
fi