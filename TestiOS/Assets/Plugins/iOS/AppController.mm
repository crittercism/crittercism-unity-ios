#import "UnityAppController.h"
#import "iPhone_Sensors.h"

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CADisplayLink.h>
#import <UIKit/UIKit.h>
#import <Availability.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/glext.h>

#include <mach/mach_time.h>

// MSAA_DEFAULT_SAMPLE_COUNT was moved to iPhone_GlesSupport.h
// ENABLE_INTERNAL_PROFILER and related defines were moved to iPhone_Profiler.h
// kFPS define for removed: you can use Application.targetFrameRate (30 fps by default)
// DisplayLink is the only run loop mode now - all others were removed

#include "CrashReporter.h"
#include "iPhone_Common.h"
#include "iPhone_OrientationSupport.h"
#include "iPhone_Profiler.h"
#include "iPhone_View.h"

#include "UI/Keyboard.h"
#include "UI/UnityView.h"
#include "Unity/DisplayManager.h"
#include "Unity/EAGLContextHelper.h"
#include "Unity/GlesHelper.h"

//	The IDs will be pulled from CrittercismIDs.plist in the main bundle if this file exists
const char* kCrittercism_App	= "YOUR_APP_ID";   // Your App ID Goes Here

//	Crittercism Call into library for init
extern "C" void Crittercism_EnableWithAppID(const char* appID);

// Time to process events in seconds.
#define kInputProcessingTime                    0.001

// --- Unity ------------------------------------------------------------------
//

void UnityPlayerLoop();
void UnityFinishRendering();
void UnityInitApplication(const char* appPathName);
void UnityLoadApplication();
void UnityPause(bool pause);
void UnityReloadResources();
void UnitySetAudioSessionActive(bool active);
void UnityCleanup();

void UnityGLInvalidateState();

void UnitySendLocalNotification(UILocalNotification* notification);
void UnitySendRemoteNotification(NSDictionary* notification);
void UnitySendDeviceToken(NSData* deviceToken);
void UnitySendRemoteNotificationError(NSError* error);
void UnityInputProcess();
void UnitySetInputScaleFactor(float scale);
float UnityGetInputScaleFactor();
int  UnityGetTargetFPS();

extern bool UnityUse32bitDisplayBuffer();
extern bool UnityUse24bitDepthBuffer();

int     UnityGetDesiredMSAASampleCount(int defaultSampleCount);
void    UnityGetRenderingResolution(unsigned* w, unsigned* h);

enum TargetResolution
{
	kTargetResolutionNative = 0,
	kTargetResolutionAutoPerformance = 3,
	kTargetResolutionAutoQuality = 4,
	kTargetResolution320p = 5,
	kTargetResolution640p = 6,
	kTargetResolution768p = 7
};

int UnityGetTargetResolution();
int UnityGetDeviceGeneration();
void UnityRequestRenderingResolution(unsigned w, unsigned h);

void SensorsCleanup();

bool    _ios43orNewer       = false;
bool    _ios50orNewer       = false;
bool    _ios60orNewer       = false;
bool    _ios70orNewer       = false;

bool    _supportsDiscard        = false;
bool    _supportsMSAA           = false;
bool    _supportsPackedStencil  = false;

bool    _glesContextCreated = false;
bool    _unityLevelReady    = false;
bool    _skipPresent        = false;

static DisplayConnection* _mainDisplay = 0;


// --- OpenGLES --------------------------------------------------------------------
//

CADisplayLink*          _displayLink;

// This is set to true when applicationWillResignActive gets called. It is here
// to prevent calling SetPause(false) from applicationDidBecomeActive without
// previous call to applicationWillResignActive
BOOL                    _didResignActive = NO;


static void
QueryTargetResolution(int* targetW, int* targetH)
{
	int targetRes = UnityGetTargetResolution();

	float resMult = 1.0f;
	if(targetRes == kTargetResolutionAutoPerformance)
	{
		switch(UnityGetDeviceGeneration())
		{
			case deviceiPhone4:     resMult = 0.6f;     break;
			case deviceiPad1Gen:    resMult = 0.5f;     break;

			default:                resMult = 0.75f;
		}
	}

	if(targetRes == kTargetResolutionAutoQuality)
	{
		switch(UnityGetDeviceGeneration())
		{
			case deviceiPhone4:     resMult = 0.8f;     break;
			case deviceiPad1Gen:    resMult = 0.75f;    break;

			default:                resMult = 1.0f;
		}
	}

	switch( targetRes )
	{
		case kTargetResolution320p:
			*targetW = 320;
			*targetH = 480;
			break;

		case kTargetResolution640p:
			*targetW = 640;
			*targetH = 960;
			break;

		case kTargetResolution768p:
			*targetW = 768;
			*targetH = 1024;
			break;

		default:
			*targetW = _mainDisplay->screenSize.width * resMult;
			*targetH = _mainDisplay->screenSize.height * resMult;
			break;
	}
}

void PresentMainView()
{
	if(_skipPresent || _didResignActive)
	{
		UNITY_DBG_LOG ("SKIP PresentSurface %s\n", _didResignActive ? "due to going to background":"");
		return;
	}
	UNITY_DBG_LOG ("PresentSurface:\n");
	[_mainDisplay present];
}




void PresentContext_UnityCallback(struct UnityFrameStats const* unityFrameStats)
{
	Profiler_FrameEnd();
	PresentMainView();
	Profiler_FrameUpdate(unityFrameStats);
}


int OpenEAGL_UnityCallback(UIWindow** window, int* screenWidth, int* screenHeight,  int* openglesVersion)
{
	int resW=0, resH=0;
	QueryTargetResolution(&resW, &resH);

	[_mainDisplay createContext:nil];

	*window         = UnityGetMainWindow();
	*screenWidth    = resW;
	*screenHeight   = resH;
	*openglesVersion= _mainDisplay->surface.context.API;

	[EAGLContext setCurrentContext:_mainDisplay->surface.context];

	return true;
}

int GfxInited_UnityCallback(int screenWidth, int screenHeight)
{
	InitGLES();
	_glesContextCreated = true;
	[GetAppController().unityView recreateGLESSurface];

	_mainDisplay->surface.allowScreenshot = true;

	SetupUnityDefaultFBO(&_mainDisplay->surface);
	glViewport(0, 0, _mainDisplay->surface.targetW, _mainDisplay->surface.targetH);

	return true;
}

void NotifyFramerateChange(int targetFPS)
{
	if( targetFPS <= 0 )
		targetFPS = 60;

	int animationFrameInterval = (60.0 / (targetFPS));
	if (animationFrameInterval < 1)
		animationFrameInterval = 1;

	[_displayLink setFrameInterval:animationFrameInterval];
}

void LogToNSLogHandler(LogType logType, const char* log, va_list list)
{
	NSLogv([NSString stringWithUTF8String:log], list);
}

void UnityInitTrampoline()
{
#if ENABLE_CRASH_REPORT_SUBMISSION
	SubmitCrashReportsAsync();
#endif
#if ENABLE_CUSTOM_CRASH_REPORTER
	InitCrashReporter();
#endif

	_ios43orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"4.3" options: NSNumericSearch] != NSOrderedAscending;
	_ios50orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"5.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios60orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"6.0" options: NSNumericSearch] != NSOrderedAscending;
	_ios70orNewer = [[[UIDevice currentDevice] systemVersion] compare: @"7.0" options: NSNumericSearch] != NSOrderedAscending;

	// Try writing to console and if it fails switch to NSLog logging
	fprintf(stdout, "\n");
	if (ftell(stdout) < 0)
		SetLogEntryHandler(LogToNSLogHandler);
}


// --- AppController --------------------------------------------------------------------
//


@implementation UnityAppController

@synthesize unityView			= _unityView;
@synthesize rootView			= _rootView;
@synthesize rootViewController	= _rootController;

- (void)repaintDisplayLink
{
	[_displayLink setPaused: YES];
	{
		static const CFStringRef kTrackingRunLoopMode = CFStringRef(UITrackingRunLoopMode);
		while (CFRunLoopRunInMode(kTrackingRunLoopMode, kInputProcessingTime, TRUE) == kCFRunLoopRunHandledSource)
			;
	}
	[_displayLink setPaused: NO];

	if(_didResignActive)
		return;

	SetupUnityDefaultFBO(&_mainDisplay->surface);

	CheckOrientationRequest();
	[GetAppController().unityView recreateGLESSurfaceIfNeeded];

	Profiler_FrameStart();
	UnityInputProcess();
	UnityPlayerLoop();

	[[DisplayManager Instance] presentAllButMain];

	SetupUnityDefaultFBO(&_mainDisplay->surface);
}

- (void)startUnity:(UIApplication*)application
{
	char const* appPath = [[[NSBundle mainBundle] bundlePath]UTF8String];
	UnityInitApplication(appPath);

	[[DisplayManager Instance] updateDisplayListInUnity];

	OnUnityInited();
	UnitySetInputScaleFactor([UIScreen mainScreen].scale);

	UnityLoadApplication();
	Profiler_InitProfiler();

	_unityLevelReady = true;
	OnUnityReady();

	// Frame interval defines how many display frames must pass between each time the display link fires.
	int animationFrameInterval = 60.0 / (float)UnityGetTargetFPS();
	assert(animationFrameInterval >= 1);

	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(repaintDisplayLink)];
	[_displayLink setFrameInterval:animationFrameInterval];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (UnityView*)initUnityViewImpl
{
	return [[UnityView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}
- (UnityView*)initUnityView
{
	_unityView = [self initUnityViewImpl];
	_unityView.contentScaleFactor = [UIScreen mainScreen].scale;
	_unityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	return _unityView;
}

- (void)createViewHierarchyImpl
{
	_rootView = _unityView;
	_rootController = [[UnityDefaultViewController alloc] init];
}

- (void)createViewHierarchy
{
	[self createViewHierarchyImpl];
	NSAssert(_rootView != nil, @"createViewHierarchyImpl must assign _rootView");
	NSAssert(_rootController != nil, @"createViewHierarchyImpl must assign _rootController");

	_rootView.contentScaleFactor = [UIScreen mainScreen].scale;
	_rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	_rootController.wantsFullScreenLayout = TRUE;
	_rootController.view = _rootView;
	if([_rootController isKindOfClass: [UnityViewControllerBase class]])
		[(UnityViewControllerBase*)_rootController assignUnityView:_unityView];
}

- (void)showGameUI:(UIWindow*)window
{
	[window addSubview: _rootView];
	window.rootViewController = _rootController;
	[window bringSubviewToFront: _rootView];
}

- (void)onForcedOrientation:(ScreenOrientation)orient
{
	[_unityView willRotateTo:orient];
	OrientView(_rootView, orient);
	[_rootView layoutSubviews];
	[_unityView didRotate];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	// UIInterfaceOrientationMaskAll
	// it is the safest way of doing it:
	// - GameCenter and some other services might have portrait-only variant
	//     and will throw exception if portrait is not supported here
	// - When you change allowed orientations if you end up forbidding current one
	//     exception will be thrown
	// Anyway this is intersected with values provided from UIViewController, so we are good
	return   (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationPortraitUpsideDown)
		   | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationLandscapeLeft);
}

- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
	UnitySendLocalNotification(notification);
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	UnitySendRemoteNotification(userInfo);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	UnitySendDeviceToken(deviceToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	UnitySendRemoteNotificationError(error);
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	printf_console("-> applicationDidFinishLaunching()\n");
    
    //	Initialize Crittercism so we can see unity startup crashes
	initHandler = NSGetUncaughtExceptionHandler();
    Crittercism_EnableWithAppID(kCrittercism_App);
    critHandler = NSGetUncaughtExceptionHandler();
    
    NSLog(@"#### didFinishLaunchingWithOptions: %@", launchOptions);
    
    int64_t delayInSeconds = 30; // Your Game Interval as mentioned above by you
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSUncaughtExceptionHandler* beforeCrash = NSGetUncaughtExceptionHandler();
        NSLog(@"Init:%p Crit:%p BeforeCrash:%p",initHandler,critHandler,beforeCrash);
        NSLog(@"Crashing.");
        
        int* p=0;
        *p = 1;
    });

    
    
    
	// get local notification
	if (&UIApplicationLaunchOptionsLocalNotificationKey != nil)
	{
		UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
		if (notification)
			UnitySendLocalNotification(notification);
		}

	// get remote notification
	if (&UIApplicationLaunchOptionsRemoteNotificationKey != nil)
	{
		NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (notification)
			UnitySendRemoteNotification(notification);
		}

	if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == NO)
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

	[DisplayManager Initialize];
	_mainDisplay = [[DisplayManager Instance] mainDisplay];
	[_mainDisplay createView:YES showRightAway:NO];

	[KeyboardDelegate Initialize];
	CreateViewHierarchy();

	[self performSelector:@selector(startUnity:) withObject:application afterDelay:0];

	return NO;
}

// For iOS 4
// Callback order:
//   applicationDidResignActive()
//   applicationDidEnterBackground()
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	printf_console("-> applicationDidEnterBackground()\n");
}

// For iOS 4
// Callback order:
//   applicationWillEnterForeground()
//   applicationDidBecomeActive()
- (void)applicationWillEnterForeground:(UIApplication *)application
{
	printf_console("-> applicationWillEnterForeground()\n");
	// if we were showing video before going to background - the view size may be changed while we are in background
	[GetAppController().unityView recreateGLESSurfaceIfNeeded];
}

- (void)applicationDidBecomeActive:(UIApplication*)application
{
	printf_console("-> applicationDidBecomeActive()\n");
	if (_didResignActive)
		UnityPause(false);

	_didResignActive = NO;
}

- (void)applicationWillResignActive:(UIApplication*)application
{
	printf_console("-> applicationWillResignActive()\n");
	UnityPause(true);

	extern void UnityStopVideoIfPlaying();
	UnityStopVideoIfPlaying();

	_didResignActive = YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	printf_console("WARNING -> applicationDidReceiveMemoryWarning()\n");
}

- (void)applicationWillTerminate:(UIApplication*)application
{
	printf_console("-> applicationWillTerminate()\n");

	Profiler_UninitProfiler();

	UnityCleanup();
}

- (void)dealloc
{
	SensorsCleanup();
	ReleaseViewHierarchy();
	[super dealloc];
}
@end


