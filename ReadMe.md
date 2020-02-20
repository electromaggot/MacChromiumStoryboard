MacChromiumStoryboard
===================

Shows how to make [Chromium](https://www.chromium.org/Home) run in a storyboard of a macOS app.

This is relevant if you need to display web content, particularly [Angular](https://angular.io/),
inside your app's native UI navigation tree, where you may have previously wrapped Apple's native
[WKWebView](https://developer.apple.com/documentation/webkit/wkwebview) (or formerly UIWebView or
WebView), but you encountered compatibility issues forcing you to replace WKWebView with a Chromium
Embedded Framework (CEF) view.

[CEF](https://github.com/chromiumembedded/cef) is a challenge to integrate into an Xcode storyboard.
Chromium itself is heavy, incorporating not only an optimized HTML rendering engine (with GPU acceleration
and much more), but an entire Javascript compiler ([V8](https://v8.dev/)).
For security, CEF runs "sandboxed" as two separate processes (Render & Browse), which must coordinate
through [IPC](https://en.wikipedia.org/wiki/Inter-process_communication)/semaphores.  It requires its own
message pump... which unfortunately conflicts with your Mac app's own message pump.  So the two must be
blended and it gets complicated quickly.

This project also scratches the surface on building CEF V8 objects (demonstrated below) in Swift.
Those allow web page Javascript (running in the locked-down Render process) to "cross the gap" to make
inter-process calls into Swift code (on the Browse process side, which can access resources on the PC)...
but again, in that security, lies complexity. 

If you're trudging through this same quagmire in the dark, hopefully this demo can shed some light;
I've been there and wanted to share my travails.
Unfortunately I can no longer support this codebase.  I have moved on from web-related development
and projects like this, so I can only offer it as suggestion to help illuminate your way.

However, I welcome pull requests if you've fixed bugs or have made big improvements.

Additional Notes
----------------
Windows developers have [CefSharp](https://cefsharp.github.io/), which despite its claim of being
"a 'lightweight' .NET wrapper around CEF," is a big project with robust developer contributions and support.
We have no such benefit on the macOS/Swift side, with the exception of lvsti's excellent
[CEF.swift](https://github.com/lvsti/CEF.swift) project\*, which I depend on here.

CefSharp conveniently supports V8 objects, through which your app can interact with Javascript running
in the CEF view.  V8 support implemented here is far from a full implementation, but feel free to build
upon what I started.  Again, I would welcome contributions in that regard.

\* - Unfortunaely, CEF.swift appears to have fallen behind in active development and may not support the
latest versions of Chromium.  Worse, our project here is probably destined to follow.  UNLESS someone
wants to take over the reins... (please contact me if so!)

Example HTML File
-----------------
`demoIndex.html`, which loads into the CEF web view, contains some buttons/links you can click.
When you do, here's a synopsis of what happens:

RENDER SIDE (this is the restricted process that renders your page and runs your javascript; it has no access to local PC resources)

1. Page content, click:  button-like `<a href="" onclick="jsMethod()"> button </a>`.
2. Page content, calls:  `<script type="application/javascript>  function jsMethod() { ... jsHandler.method() ... }  </script>` 
3. App's Swift code:  V8Handler method
   on the Render side which are backed by methods that build V8 objects.
4. Those call V8 methods which call across the inter-process boundary to execute execute Swift code on the Browse side.  That code can then do things like open a file or pop-up a "file picker" in order to upload a file to a server.

INTER-PROCESS MESSAGE TRANSMITTED...

BROWSE SIDE (this is the unrestricted app side, which can access security-sensitive resources on the PC like the file system)

5. Message received
