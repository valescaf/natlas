#!/bin/bash

# Updates version strings and commits to version branch
# Merges version branch to master
# Switches to master, creates and pushes tag
# Prepares agent and server tarballs for release
#
# Inspiration taken from Michael Henriksen's Aquatone release script 

SLEEP_TIME=60
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CURRENT_BRANCH=$(git status | grep "On branch" | cut -d" " -f3)


if [[ $CURRENT_BRANCH == "master" ]]; then
	echo "[!] Attempting to create a release from the master branch is not currently supported."
	exit
else
	echo "[+] Building release from branch $CURRENT_BRANCH"
fi

# The CHANGELOG is very important, if you're creating a release then the CHANGELOG should be accurate.
read -p "[?] Did you remember to update CHANGELOG.md? [yN] " CHANGELOG
if [[ $CHANGELOG == "" ]] || [ $(echo "$CHANGELOG" | tr '[:upper:]' '[:lower:]') != "y" ]; then
	echo "[!] Make sure to update the changelog and then re-run the script and hit y."
	exit
else
	echo "[+] Good for you, keeping a good changelog is important"
fi

# Grab current version strings
CURRENT_SERVER_VERSION=$(cat natlas-server/config.py | grep NATLAS_VERSION | cut -d'"' -f2)
CURRENT_AGENT_VERSION=$(cat natlas-agent/config.py | grep NATLAS_VERSION | cut -d'"' -f2)

# If agent and server versions are different, something is probably wrong
if [ "$CURRENT_SERVER_VERSION" != "$CURRENT_AGENT_VERSION" ]; then
	echo "[!] Version string mismatch. Agent: $CURRENT_AGENT_VERSION Server $CURRENT_SERVER_VERSION"
	exit
else
	CURRENT_VERSION=$CURRENT_SERVER_VERSION
	echo "[+] Current version: $CURRENT_VERSION"
fi

TO_UPDATE=(
	natlas-server/config.py
	natlas-agent/config.py
)

read -p "[?] Enter new version: " NEW_VERSION


# Check to make sure the release version falls within semantic versioning guidelines
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "[!] Version $NEW_VERSION does not meet standard naming convention"
	exit
else
	echo "[+] Version $NEW_VERSION conforms to versioning standards"
fi


# Patch the version strings
echo "[+] Updating version strings. . ."
for file in "${TO_UPDATE[@]}"; do
	echo -n "[+] Patching $file. . ."
	sed -i".bak" "s/$CURRENT_VERSION/$NEW_VERSION/g" $file
	if !  grep $NEW_VERSION $file >/dev/null; then
		echo " . . .failed."
		exit
	else
		echo " . . .succeeded."
		rm $file.bak
	fi
done

# Confirm that you're ready to make changes to the repo
read -p "[?] Are you sure you're ready to release? [yN] " RELEASEME

if [[ $RELEASEME == "" ]] || [ $(echo "$RELEASEME" | tr '[:upper:]' '[:lower:]') != "y" ]; then
	echo "[!] Better get your affairs in order, then. Version strings are already updated."
	exit
else
	echo "[+] Pushing and tagging version $NEW_VERSION in $SLEEP_TIME seconds. Speak now or forever hold your peace."
	sleep $SLEEP_TIME
fi

for file in "${TO_UPDATE[@]}"; do
	echo "[+] Staging $file"
	git add $file
done

# Commit the version string changes to version branch
git commit -m "Preparing configs for v$NEW_VERSION"
git push

# Switch to master, make sure there's no upstream changes, and merge version branch to master
git checkout master
git pull origin master
git merge $CURRENT_BRANCH
git commit -m "Releasing v$NEW_VERSION"
git push

# Create a tag for the release and push it to github
git tag -a v$NEW_VERSION -m "Release v$NEW_VERSION"
git push origin v$NEW_VERSION

# Copy the LICENSE and CHANGELOG into component folders
cp LICENSE natlas-server/
cp CHANGELOG.md natlas-server/
cp LICENSE natlas-agent/
cp CHANGELOG.md natlas-agent/

# Create tarballs for components
tar cvzf natlas-server-$NEW_VERSION.tgz --exclude-from=.gitignore natlas-server/
tar cvzf natlas-agent-$NEW_VERSION.tgz --exclude-from=.gitignore natlas-agent/


echo "[+] Version v$NEW_VERSION released."
echo "[+] Don't forget to upload natlas-server-$NEW_VERSION.tgz and natlas-agent-$NEW_VERSION.tgz to the Github release page."