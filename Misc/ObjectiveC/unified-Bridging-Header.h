//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

// IMPORTANT NOTE that Xcode must be made aware of this file in:
//	Build Settings > Swift Compiler - General > Objective-C Bridging Header

// Objective-C API to local hardware interface addresses, such as our IPv4 address:
#import <ifaddrs.h>
// (Note that what we really want is for the above to resolve to this, regardless of specific Xcode_<version>.app and MacOSX<ver.sion>.sdk...)
//  #import "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/ifaddrs.h"

// Allow catch of Objective-C exceptions:
#import "./ObjC.h"
