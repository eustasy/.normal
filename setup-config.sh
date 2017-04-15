#!/bin/sh
# Copy config files

set -e

echo "####################"
echo "Starting Config Copy"
echo "####################"

cp normal-checks/.codeclimate.yml  .codeclimate.yml
cp normal-checks/.eslintrc.json    .eslintrc.json
cp normal-checks/.eslintignore     .eslintignore
cp normal-checks/.mdlrc            .mdlrc
cp normal-checks/.mdlrc.style.rb   .mdlrc.style.rb
cp normal-checks/.stylelintrc.json .stylelintrc.json
cp normal-checks/.stylelintignore  .stylelintignore

if ! git --no-pager diff --quiet; then
    git --no-pager diff

    echo "#################################"
    echo "WARNING! Config changes detected."
    echo "#################################"

    exit 0;
else
    echo "#####################"
    echo "Config copy complete!"
    echo "#####################"

    exit 0;
fi

