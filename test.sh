#!/bin/sh
set -eu

dataDir="$(pwd)"
outputDir="$dataDir/build"

rm -rf "$outputDir"
mkdir -p "$outputDir"

docker build -t marp-plus-cli .

docker run --rm -u "$(id -u):$(id -g)" -v "$dataDir":/app -w /app marp-plus-cli sub/ --theme-filter tech-marp --theme-set https://atechpublic.z13.web.core.windows.net/style/marp.css --keep-dirs --embed-images -o ./build/

find "$outputDir" -type f | sort

echo
for expected in "example.html" "sub-sub/example2.html"; do
  if [ ! -f "$outputDir/$expected" ]; then
    echo "FAIL: missing $expected"
    exit 1
  fi
done

if [ -f "$outputDir/example3.html" ] || [ -f "$outputDir/sub-sub/example3.html" ]; then
  echo "FAIL: example3.html should not be generated"
  exit 1
fi

if ! grep -q 'data:image/svg+xml;base64' "$outputDir/sub-sub/example2.html"; then
  echo "FAIL: example2.html did not embed the background image as base64"
  exit 1
fi

if ! grep -q 'background-size:30%' "$outputDir/sub-sub/example2.html"; then
  echo "FAIL: example2.html did not preserve background-size for embedded background image"
  exit 1
fi

if grep -q 'embedded-diagram\.svg' "$outputDir/sub-sub/example2.html"; then
  echo "FAIL: example2.html still contains a raw embedded-diagram.svg reference"
  exit 1
fi

echo "PASS: example.html and example2.html generated, example3.html not generated, background image embedded and scaled correctly."