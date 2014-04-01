Overview
==========

[Crittercism](http://www.crittercism.com) helps developers track and manage performance of mobile applications on several platforms. In its default configuration, the library offers two key benefits:

* **App Load Tracking** When the user begins using an instrumented application, the library records an app load event. Crittercism aggregates app loads into rolling daily and monthly active user counts using a Crittercism generated unique identifier, and delivers insight into the relative popularity of the application's released versions.

* **Unhandled Exception Tracking** When an unhandled exception occurs, the library records device state and a stack trace for immediate/delayed (depending on platform) transmission to Crittercism. Crittercism informs the developer of the error, and provides the information necessary to reproduce the issue in local development / testing.

In addition to crash reporting, the library provides calls for setting timestamped checkpoints (or Breadcrumbs), recording arbitrary user state (or Metadata]), and saving stack traces with developer-provided messages on arbitrary code paths (or Handled Exceptions).

Learn more about what Crittercism provides with the [solution overview][14].

About the Plugin
==================

The plugin will capture more on iOS and the most detailed exceptions when **"Script Call Optimizations"** are set to **"Slow, but Safe."**. Exception handlers are otherwise stripped from the Unity3D engine and have to be handled outside the Mono Environment. In these cases, symbols captured will be relevant to the Unity3d Engine code, _not_ the C# or Javascript code. These settings can be found in the **iOS Player settings**, reachable with the menu from **“Edit->Project Settings->Player”**, then under the **“Other Settings”** category.

Supporting the Plugin
=======================

This is our first open source project here at Crittercism as with regular updates to Unity and different development scenarios a Unity Plugin can be a complicated project to maintain. That's why we'd love your help!

Getting Involved, Some Guidelines
-----------------------------------

#### Filing a Ticket

Github provides us a medium to publicly file tickets and report issues; you can do so [here][12]. As for what each ticket contains, here are some guidelines of what will make solving an issue easier for everyone:

* Items to include in a ticket:
	- Source of the issue (who reported it)
	- Version of Unity effected
	- Version of iOS/Android/etc effected
	- Version of XCode/Eclipse/Android API
	- Date discovered (versus date filed)
	- Any related Crittercism Crash Report links as examples
* Give a scenario, if one is clear, in which the issue is reproduced

#### Writing Commits

Writing a commit should be simple, but here are some guidelines that will help us all be clear:

* Be clear about what each commit contains (such as feature or process updated, specific bug fixed, etc)
* Be concise and commit often, preferably after a smaller task is complete and tested

#### Submitting a Pull Request

Pull Requests are generally related to specific bugs, features, updates and are best created via forking the existing repository and making the changes in your personal repository; learn more about [Pull Requests][13] from Github. When submitting a pull request there are a few items to keep in mind that will make everyones lives easier:

* Keep the requests small, having a large number of commits can create a large time commitment for those reviewing the request
* Sign off the code to adhere to the DCO (found below) using the following example:
	```
	Signed-off-by: John Doe <john.doe@hisdomain.com>
	```

Make sure the above sign-off is verbatim and uses your real name and most accurate email.

Installing the Plugin
=======================

Installing the Crittercism iOS Unity Plugin starts by downloading the latest iOS Unity.

The repository includes the following items:
* **Plugins/iOS** - Contains the static library generated from the Plugin Source (which includes the Crittercism Static Library)
* **Plugins/Crittercism_iOS_Scripts** - Contains an Init Script, the Plugin Script, and the Test GUI Script
* **Plugins/PluginSource** - Contains the source project for the Unity plugin
* **TestiOS** - An example app that provides a reference of usage for features
* **Docs** - Contains an offline reference to the docs

Crittercism for iOS works with iOS 5.0+, armv7 and armv7s, with both device and simulator support. Crittercism for iOS Unity works with Unity 3.4.0+.

Adding the Library to your Project
------------------------------------

Drag and drop the following items into your project:

	iOS_Unity/Plugins/iOS						--->	Assets/Plugins/iOS
	iOS_Unity/Plugins/Crittercism_iOS_Scripts	--->	Assets/Plugins/Crittercism_iOS_Scripts

If you already have other iOS Plugins, the contents of these folders should be copied over.

Initializing Crittercism
--------------------------

### Generic App Controller

Crashes that occur before Crittercism is started in Unity are not handled. If you would like these to be handled by Crittercism, then you'll need to initialize Crittercism even earlier!

We've made this a bit easier by providing several AppControllers.mm files included in for various verions of Unity:
​Crittercism_Unity_iOS/AppControllers/

The correct AppController file should be selected and copied to the **(Unity Project)/Assets/Plugins/ios/** folder, and rename it AppController.mm. Use of the wrong file will result in the application failing to compile.

Can't find your version of Unity? Don't worry, creating a new AppController is pretty simple. Follow the below steps and you'll get yourself a new AppController.

1. Create a simple Unity project
2. Build for iOS, this should open XCode
3. In XCode, under the **"Classes"** project sub folder, find **"UnityAppController.mm"**
4. Rename **"UnityAppController.mm"** to **"AppController.mm"**
5. Follow the below instructions for modifying a Custom AppController
6. Copy the new "AppController.mm" to "Plugins/iOS" in the Assets directory in your Unity project

**Note:** Help us out and add this new AppController to the Github repo! Create a pull request (described above) with the AppController.mm renamed with the version number, for example AppController4.2.1.mm under the "AppController" folder. Thanks for your help!

### Custom App Controller

If a custom AppController.mm is already being used. The Following lines will need to be added to the top of the file, and the AppID set to the values designated for your App in Crittercim web portal.

	// If CrittercismIDs.plist exists in the main bundle, ID’s will be pulled from the CrittercismIDs.plist.
	// If no CrittercismIDs.plist exists, or ID’s are not found in the file, the values
	// Below will be used.
	const char* kCrittercism_App_ID​= "";​// Your App ID Here

	// Crittercism Call into library for init
	extern "C" void Crittercism_EnableWithAppID(const char* appID);

	Add the Following Line to the top of applicationDidFinishLaunching:

	// Initialize Crittercism so we can see unity startup crashes
	Crittercism_EnableWithAppID(kCrittercism_App_ID);

**Note:** If you use a heavy mixture of native over Unity, this initialization/setup may change. The setup for this scenario is still a work in progress.

Getting Started with Advanced Features!
=========================================

Capturing uncaught exceptions is a powerful tool for any developer, but sometimes you want to do even more. That's why Crittercism provides several advanced features. Here are a few getting started tips:

Handled Exceptions
--------------------

Crittercism allows you to capture and track disruptive crashes that interrupt the flow within the app, even if the error doesn’t result in a crash by passing handled exception objects to our servers. They’ll be grouped and symbolicated much like your normal uncaught exceptions.

### How To Use Handled Exceptions ###

1. Identify potential hotspots where an error might occur. (see Use Cases below for some examples)
2. Trap the potential exceptions.
3. Analyze disruptive exceptions by viewing the stacktrace, diagnostics, metadata and breadcrumbs related to that issue.
4. Adjust the user flow in your code around exceptions to ensure the best user experience.
5. Prioritize and resolve bugs to stop your app from crashing.

### Some High-Level Use Cases ###

* Accessing data (such as over network or on local storage)
* Establishing connections (for example handling a malformed request)
* Starting background services
* Third-Party initializations/integrations

### Usage ###

Here's an example of how to use handled exceptions for Objective-C:

	@try {
		[Crittercism leaveBreadcrumb:@"Trying to ______"];
		// Make network connection
		// or add to JSON object
		// or access local storage
		// or start background service
	}
	@catch (NSException error) {
		[Crittercism leaveBreadcrumb:@"Failed to ______"];
		[Crittercism logHandledException: error];
	}

Breadcrumbs
-------------

Sometimes a stack trace just isn’t enough. By placing breadcrumbs in your code, you can get a playback of events in the run-up to a crash or exception. For each session, our libraries automatically store a "session_start" breadcrumb to mark the beginning of a user session, and the most recent 99 breadcrumbs that were left before a crash. To leave a breadcrumb, simply insert an API call at points of interest in your code after instantiating Crittercism. Each breadcrumb can contain up to 140 characters.

### How To Use Breadcrumbs ###

1. Identify potential session events/state/variables to capture for debugging.
2. Place breadcrumbs surrounding these events/state/variables.
3. Analyze session events/state/variables to hasten tracking down the culprit of an issue.
4. Combine this information with stack traces, diagnostics, and metadata to prioritize and resolve bugs around these events.

### Some High-Level Use Cases ###

* Measuring time performance for UX
* Identifying hotspots within your application and/or functionality
* Tracking variables or state throughout the user flow
* Flagging events within callbacks (such as low memory warnings)

### Usage ###

Here's an example of how to use breadcrumbs for Objective-C (accepts 140 characters):

	[Crittercism leaveBreadcrumb:@"Class \\ Selector \\ Activity "]; // An example use, any string works

User Metadata
---------------

You can attach metadata to each user. This data will help you differentiate users on both the portal and the client. For example, if you specify a username, it will appear in the client when the user leaves feedback. On the portal, the specified username will appear both in the forum, as well as in the Crash Report tab (under Affected Users when you select a specific user), allowing you to correlate data and respond to support tickets with greater knowledge.

You can also attach an arbitrary amount of metadata to each user through a method accepting key and value parameters. The data will be stored in a dictionary and displayed in the Crittercism Portal when viewing a user profile.

**Crittercism takes user privacy very seriously** and as such if you are spotted sending Device Identifiers or other personally identifying information that isn't helpful for debugging a crash we will ask you to please remove the gathering of this information through our service.

### How To Use MetaData ###

1. Identify potential user events/state/variables to capture for debugging.
2. Assign arbitrary metadata during these events.
3. Analyze user events/state/variables to hasten tracking down the culprit of an issue.
4. Combine this information with stack traces and diagnostics to prioritize and resolve bugs around these events.

### Some High-Level Use Cases ###

* Track shopping cart or transaction information of the user at time of crash
* State within the user flow (such as level of game, location, or view of app)

### Usage ###

Here's an example of how to use user metadata for Objective-C:

	// Early on in the game session or when the user changes their username (if possible)
	[Crittercism setUsername:@"TheCritter"];

	[Crittercism setValue:@"GameLevel" forKey:@"5"];
	// next level
	[Crittercism setValue:@"GameLevel" forKey:@"6"];

	// Track the cart items for a transaction (an example of converting a Dictionary to a string)
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"Carrot Helmet" forKey:@"6345234"];

	//[NSString stringWithFormat:@"%@", dict]; // another way
	NSString *jsonString = [dict JSONRepresentation]; // using [json-framework](http://code.google.com/p/json-framework/)
	[Crittercism setValue:jsonString forKey:@"CartItems"];

This will keep track of the players state and settings so you can get more specifics relevant to your application!

Developer Certificate of Origin
=================================

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

Change Log
------------

2.9.2014. Refreshed the documentation!
3.31.2014 Fixed some links that didn't display correctly on Github

[2]: htttp://support.crittercism.com "Crittercism Help"
[12]: https://github.com/crittercism/crittercism-unity-ios/issues "Unity iOS Issues"
[13]: https://help.github.com/articles/using-pull-requests "Pull Requests - Github"
[14]: https://www.crittercism.com/solution-overview/ "Solution Overview"
