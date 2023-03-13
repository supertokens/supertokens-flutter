#!/bin/bash
# get current version
# get sdk version----------
version=`cat ../pubspec.yaml | grep -e 'version:'`
while IFS=':' read -ra ADDR; do
    counter=0
    for i in "${ADDR[@]}"; do
        if [ $counter == 1 ]
        then
            version=$i
        fi
        counter=$(($counter+1))
    done
done <<< "$version"

version=`echo $version | xargs`
# replace path version with X
IFS='.' read -r -a array <<< "$version"
versionFolder="${array[0]}"."${array[1]}".X

(cd ../../supertokens-backend-website && mkdir -p ./app/docs/sdk/docs/flutter/${versionFolder})
cp -r ../doc/api/* ../../supertokens-backend-website/app/docs/sdk/docs/flutter/
cp -r ../doc/api/* ../../supertokens-backend-website/app/docs/sdk/docs/flutter/${versionFolder}

git config --global user.email "$EMAIL"
git config --global user.name "$NAME"
(cd ../../supertokens-backend-website && git add --all && git commit -m"updates flutter sdk docs" && git pull && git push && ./releaseDev.sh)