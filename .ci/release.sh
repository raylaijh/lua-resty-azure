#!/bin/bash

if [ -z "$LUAROCKS_TOKEN" ]
then
  echo "!! Environment variable LUAROCKS_TOKEN is not set, for release !!"
  exit 1
fi

if [ -z "$RELEASE_TYPE" ]
then
  echo "!! Make argument RELEASE_TYPE is not set !!"
  echo ""
  echo "Usage:"
  echo "      make release RELEASE_TYPE=[major,minor,patch]"
  echo ""
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
  echo '!! You need to be on main branch to perform a release !!';
  exit 1;
fi

CURRENT_VERSION=$(awk '/local package_version/{gsub(/"/, "", $NF); print $NF}' lua-resty-azure-*.rockspec)
echo "> Current version is: ${CURRENT_VERSION}"

while IFS='.' read -ra VERSION_PARTS; do
  export MAJOR_VER=${VERSION_PARTS[0]}
  export MINOR_VER=${VERSION_PARTS[1]}
  export PATCH_VER=${VERSION_PARTS[2]}

done <<< "$CURRENT_VERSION"

echo "> Split... Major: ${MAJOR_VER} | Minor: ${MINOR_VER} | Patch: ${PATCH_VER}"
if [[ "$RELEASE_TYPE" == "major" ]]
then
  echo "> Release is major"
  export MAJOR_VER=$((MAJOR_VER + 1))
  export MINOR_VER="0"
  export PATCH_VER="0"
  echo "> Major ver increment is ${MAJOR_VER}"
elif [[ "$RELEASE_TYPE" == "minor" ]]
then
  echo "> Release is minor"
  export MINOR_VER=$((MINOR_VER + 1))
  export PATCH_VER="0"
  echo "> Minor ver increment is ${MINOR_VER}"
elif [[ "$RELEASE_TYPE" == "patch" ]]
then
  echo "> Release is patch"
  export PATCH_VER=$((PATCH_VER + 1))
  echo "> Patch ver increment is ${PATCH_VER}"
else
  echo "!! Make argument RELEASE_TYPE value ${RELEASE_TYPE} is not valid !!"
  echo ""
  echo "Usage:"
  echo "      make release RELEASE_TYPE=[major,minor,patch]"
  echo ""
  exit 1
fi

NEXT_VERSION="${MAJOR_VER}.${MINOR_VER}.${PATCH_VER}"
echo ""
echo ">> NEXT VERSION IS: ${NEXT_VERSION}"
echo ""

git checkout -b release/${NEXT_VERSION}

NEXT_VERSION_FILENAME="lua-resty-azure-${NEXT_VERSION}-1.rockspec"
mv lua-resty-azure-*.rockspec ${NEXT_VERSION_FILENAME}
echo "> Moved rockspec file to new version: ${NEXT_VERSION_FILENAME}"
ls -la ${NEXT_VERSION_FILENAME}

sed -i "s/^local package_version = \"$CURRENT_VERSION\"/local package_version = \"$NEXT_VERSION\"/" ${NEXT_VERSION_FILENAME}
echo "> Updated rockspec version key to ${NEXT_VERSION}"

git add .

git commit -m "release ${NEXT_VERSION}"
git tag "${NEXT_VERSION}"
git checkout main
git merge release/${NEXT_VERSION}
git branch -D release/${NEXT_VERSION}

echo ""
echo "> UPLOADING TO LUAROCKS"

echo ""
echo ">> POSTing rockspec to Luarocks"
echo ""

curl -f -k -L --silent \
  --user-agent "lua-resty-azure upload script via curl" \
  --form "rockspec_file=@lua-resty-azure-$NEXT_VERSION-1.rockspec" \
  --connect-timeout 30 \
  "https://luarocks.org/api/1/$LUAROCKS_TOKEN/upload" \
  -o "./upload1.json"

if [ ! -f /tmp/upload1.json ];
then
  echo "!! Rockspec upload appears to have failed !!"
  exit 1
fi

if ! export LR_ROCK_VERSION_ID=$(jq .version.id < /tmp/upload1.json)
then
  echo "!! Rockspec upload failed - do a `git reset --hard` and retry !!"
  exit 1
fi

echo ""
echo ">> Captured release ID: $LR_ROCK_VERSION_ID - forming rock src directory"
echo ""

mkdir -p /tmp/release/lua-resty-azure
cd /tmp/release

cp -R /host/resty lua-resty-azure/resty
find . -name '.DS_Store' -type f -delete
cp /host/README.md /tmp/release/lua-resty-azure/
cp /host/lua-resty-azure-$NEXT_VERSION-1.rockspec /tmp/release/lua-resty-azure-$NEXT_VERSION-1.rockspec
cp /host/lua-resty-azure-$NEXT_VERSION-1.rockspec /tmp/release/lua-resty-azure/lua-resty-azure-$NEXT_VERSION-1.rockspec

echo ""
echo ">> Compressing rock src"
echo ""
zip -r lua-resty-azure-$NEXT_VERSION-1.src.rock .
ls -la

echo ""
echo ">> Uploading rock src to Luarocks"
echo ""

curl -f -k -L --silent \
  --user-agent "lua-resty-azure upload script via curl" \
  --form "rock_file=@lua-resty-azure-$NEXT_VERSION-1.src.rock" \
  --connect-timeout 30 \
  "https://luarocks.org/api/1/$LUAROCKS_TOKEN/upload_rock/$LR_ROCK_VERSION_ID" \
  -o "./upload2.json"

echo ">>> src upload response:: $(cat upload2.json)"

echo ""
echo ">>> COPYING lua-resty-azure-$NEXT_VERSION-1.src.rock to host for verification"
echo ""
cp lua-resty-azure-$NEXT_VERSION-1.src.rock /host/

echo ""
echo ">>> RELEASE IS DONE! <<<"
echo ""
echo "Make sure you push the remote to the origin:"
echo "    $ git push --tags origin main"
echo ""

exit 0
