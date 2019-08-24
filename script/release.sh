#!/bin/sh
set -e

cd $( dirname "$0" )/..

# refs/tags/v0.0.1 becomes just v0.0.1
TAG=$( echo $GITHUB_REF | sed -e 's/refs\/tags\///g' )

# https://developer.github.com/v3/repos/releases/#create-a-release
# Generate well-formed JSON, using jq
data=$( jq --null-input \
  --arg tag_name "${TAG}" \
  --arg target_commitish "${GITHUB_SHA}" \
  --arg name "Release ${TAG}" \
  '{ "tag_name": $tag_name, "target_commitish": $target_commitish, "name": $name }'
)

# Create release
response=$( curl --request POST \
  --url https://api.github.com/repos/${GITHUB_REPOSITORY}/releases \
  --header "authorization: token ${GITHUB_TOKEN}" \
  --header 'content-type: application/json' \
  --data "${data}"
)

# Get the upload URL for this release
upload_url=$( echo $response | \
  jq --raw-output '.upload_url' | \
  sed -Ee 's/\{\?.+\}//g'
)

# https://developer.github.com/v3/repos/releases/#upload-a-release-asset
response=$( curl --request POST \
  --url "${upload_url}?name=Bearflow.alfredworkflow" \
  --header "authorization: token ${GITHUB_TOKEN}" \
  --header 'content-type: application/zip' \
  --form 'data=@Bearflow.alfredworkflow'
)

browser_download_url=$( echo $response | \
  jq --raw-output '.browser_download_url'
)

echo "${browser_download_url} 🚀"
