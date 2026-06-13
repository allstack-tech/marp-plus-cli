#!/bin/sh
set -eu

dataDir="$(pwd)"
outputDir="$dataDir/build"

rm -rf "$outputDir"
mkdir -p "$outputDir"

docker build -t marp-plus-cli .

docker run --rm -v "$dataDir":/app -w /app marp-plus-cli sub/ --theme-filter tech-marp --theme-set https://atechpublic.z13.web.core.windows.net/style/marp.css -o ./build/

ls -1 "$outputDir"

echo
for expected in example.html example2.html; do
  if [ ! -f "$outputDir/$expected" ]; then
    echo "FAIL: missing $expected"
    exit 1
  fi
done

if [ -f "$outputDir/example3.html" ]; then
  echo "FAIL: example3.html should not be generated"
  exit 1
fi

echo "PASS: example.html and example2.html generated, example3.html not generated."