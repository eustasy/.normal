#!/bin/sh
# Copy config files

set -e

echo "##########################"
echo "Starting Permissions Check"
echo "##########################"

find . -type d -exec sudo chmod 755 {} \;
find . -type f -exec sudo chmod 644 {} \;
find . -type f -name "*.sh" -exec sudo chmod 755 {} \;

if ! git --no-pager diff --quiet; then
    git --no-pager diff
    echo "#####################################"
    echo "WARNING! Permission changes detected."
    echo "#####################################"
    exit 1;

else
    echo "###########################"
    echo "Permissions check complete!"
    echo "###########################"
    exit 0;
fi
