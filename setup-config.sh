#!/bin/sh
# Copy config files

set -e

echo "####################"
echo "Starting Config Copy"
echo "####################"

cp normal-checks/.stylelintrc.json .stylelintrc.json
cp normal-checks/.stylelintignore  .stylelintignore
cp normal-checks/.eslint.json      .eslint.json

if ! git --no-pager diff --quiet; then
    git --no-pager diff

    echo "########################"
    echo "Config changes detected."
    echo "########################"

    exit 1;
else
    echo "#####################"
    echo "Config copy complete!"
    echo "#####################"

    exit 0;
fi

