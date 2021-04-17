#!/bin/bash

echo "creating temp folder"

mkdir temp

echo "Moving files into temp"

cp CHANGELOG.md temp/CHANGELOG.md
cp README.md temp/README.md
cp LICENSE temp/LICENSE
cp CONTRIBUTING.md temp/CONTRIBUTING.md
cp -r lib/ temp/lib/
cp -r example/ temp/example
cp pubspec.yaml temp/pubspec.yaml

cd temp && flutter pub publish

cd ../ && rm -rf temp/