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
echo ">>> UPLOADING TO LUAROCKS <<<"
echo ""

#luarocks upload ${NEXT_VERSION_FILENAME} --api-key=${LUAROCKS_TOKEN}

echo ""
echo ">>> RELEASE IS DONE! <<<"
echo ""
echo "Make sure you push the remote to the origin:"
echo "    $ git push --tags origin main"
echo ""

exit 0
