#!/bin/bash
#
# Copy Chromium-related frameworks (CEF.swift build and Chromium Embedded Framework binaries)
#  from their build directories into a common root directory, which is checked into git, in
#  order to make cloud builds easier.
# The difficulty is that the CEF.swift project, while convenient to build, uses python scripts
#  to download the Chromium binaries and other tricks which flummox AzureDevOps' build system.
#
# Jensen 7 Dec 2018

DESTINATION="Frameworks"

FRAMEWORKS=(
  CEF.swift/build/Products/Debug/CEFswift.framework
  CEF.swift/build/Products/Release/CEFswift.framework
  'CEF.swift/External/cef_binary/Debug/Chromium Embedded Framework.framework'
  'CEF.swift/External/cef_binary/Release/Chromium Embedded Framework.framework'
  CEF.swift/Modules
)

if [ ! -d "$DESTINATION" ]; then
  echo "Making directory: $DESTINATION"
  mkdir "$DESTINATION"
fi

index=0
while [ "${FRAMEWORKS[index]}" != "" ]; do
  FRAMEWORK="${FRAMEWORKS[index]}"
  if [ -d "$FRAMEWORK" ]; then
    BASENAME="$(basename "$FRAMEWORK")"
    DIRNAME="$(dirname "$FRAMEWORK")"
    CONFIGURATION="${DIRNAME##*/}"
    DIRDESTINATION="$DESTINATION/$CONFIGURATION"
    FULLDESTINATION="$DIRDESTINATION/$BASENAME"
    EXTENSION="${BASENAME##*.}"
    if [ "$EXTENSION" != "framework" ]; then
      FULLDESTINATION="$DESTINATION/$BASENAME"
      DIRDESTINATION="$DESTINATION"
    fi
    if [ -d "$FULLDESTINATION" ]; then
      echo "Removing pre-existing: $FULLDESTINATION"
      rm -rf "$FULLDESTINATION"
    else
      if [ ! -d "$DIRDESTINATION" ]; then
        echo "Making directory: $DIRDESTINATION"
        mkdir "$DIRDESTINATION"
      fi
    fi
    echo "Copying: $FRAMEWORK  TO: $DIRDESTINATION"
    cp -R "$FRAMEWORK" "$DIRDESTINATION"
  else
    echo "(no $FRAMEWORK)"
  fi
  index=$(($index + 1))
done

echo DONE!

