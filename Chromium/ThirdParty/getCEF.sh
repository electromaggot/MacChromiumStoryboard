#! /bin/bash

# INSTRUCTIONS for Including the Chromium Embedded Framework
#  and the CEF.swift open source project
#  into your Mac app project.

#  1. Run the steps in SECTION TWO.  Okay while this is now reduced to one "runnable" step,
#     still take time to read and/or undertake all the steps, including the last line.
#
#  2. Open CEF.swift.xcodeproj in Xcode.
#
#    a. Turn on Code Signing for this framework/library:
#
#      i. Select CEF.swift project, CEF.swift TARGET, General tab, Signing section.
#
#      ii. Check: Automatically manage signing
#
#      iii. Continue past the warning about resetting build settings.
#
#      iv. Select for Team:  <your Apple developer account team>
#
#    b. Build.  Should succeed without any errors or warnings (except perhaps a Swift 5
#               conversion warning, which can be ignored).
#
#  3. Run:  ./copyFrameworks.sh
#     This copies the two frameworks from their build directories inside "CEF.swift" to the git'ed
#     "Frameworks" directory (i.e. gets checked into source control, streamlining cloud builds).
#
#  4. Build the main app project (here, ChromiumTester), which should seamlessly
#     incorporate these frameworks.


#----SECTION-TWO----

# You will need:

# 1. CEF Binaries
#wget http://opensource.spotify.com/cefbuilds/cef_binary_3.3359.1774.gd49d25f_macosx64.tar.bz2
#gunzip cef_binary*
# NOTE! CEF.swift now does the above automatically as part of its build process. Hence the comments.

# 2. CEF.swift Open Source
# Don't use CEF.swift's master! It's years-worth-of-commits out-of-date. Instead pull by branch:
git clone -b cef_3538 https://github.com/lvsti/CEF.swift.git

# Although just in case you've already cloned master...
#git checkout -b cef_3359
#git pull origin cef_3359

# 3. Open CEF.swift.xcodeproj in Xcode and build.
# (This will require some tools installed; see: https://github.com/lvsti/CEF.swift)

