#!/bin/sh
# Runs php -l on all php files

set -e

echo "###################"
echo "Startin PHP linting"
echo "###################"

find . -name "*.php" -print0 | xargs -0 -n1 -P8 php -l
if find . -name "*.php" -print0 | xargs -0 -n1 -P8 php -l | grep -v 'No syntax error'
then
        echo 'There are PHP errors.'
        exit 1;
fi

echo "#####################"
echo "PHP linting complete!"
echo "#####################"
