#!/bin/sh

# Stave off "code object is not signed at all" build failure
#	in "Chromium Embedded Framework.framework"
# You shouldn't need this for "CEFswift.framework" if you
#	built that yourself.  Otherwise use these same commands.

cd "Frameworks/Debug/Chromium Embedded Framework.framework"

codesign -f -s - "Chromium Embedded Framework"

cd -

cd "Frameworks/Release/Chromium Embedded Framework.framework"

codesign -f -s - "Chromium Embedded Framework"


echo DONE


# Note that some frameworks seem to get built -and distributed- incorrectly
#	anyway.  In one instance, it was necessary to, for instance:
#		cd SDL2_image.framework/Versions/A/Frameworks/webp.framework
#		rm -rf Versions
#	...then codesign of webp before codesign of SDL2_image
