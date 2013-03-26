#import "AppController.h"

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <Availability.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/glext.h>

#include <mach/mach_time.h>

//	The IDs will be pulled from CrittercismIDs.plist in the main bundle if this file exists
const char* kCrittercism_App	= "CRITTERCISM_APP_ID";   // Your App ID Goes Here

//	Crittercism Call into library for init
extern "C" void Crittercism_EnableWithAppID(const char* appID);

// USE_DISPLAY_LINK_IF_AVAILABLE
//
// Use of the CADisplayLink class is the preferred method for controlling your
// rendering loop. CADisplayLink will link to the main display and fire every
// vsync when added to a given run-loop. Other main loop types (NSTimer, Thread,
// EventPump) are used only as fallback when running on a pre 3.1 device where
// CADisplayLink is not available.
//
// NOTE: some developers reported problems with input lag while using
// CADisplayLink, so try to disable it if this is the case for you.
//
// Note that OS version and CADisplayLink support will be determined at the
// run-time automatically and you CAN compile your application using ANY SDK.
// Your application will work succesfully on pre 3.1 device too.
//
// Constants supported by this method: kFPS


// Fallback types (for pre 3.1 devices):

// NSTIMER_BASED_LOOP
//
// It is a common approach to use NSTimer for scheduling rendering on a pre 3.1
// device NSTimer approach is perfect for non-performance critical applications
// which favours battery life and scrupulous correct events processing over the
// rendering performance.
//
// Constants supported by this method: kThrottleFPS, kFPS


// THREAD_BASED_LOOP
//
// However number of games might prefer frame-rate over battery life,
// therefore Unity provide alternate methods which allows you to run in a
// tighter rendering loop.

// Thread based loop allows to get best of two worlds - fast rendering and
// guaranteed event processing.
//
// Constants supported by this method: kFPS


// EVENT_PUMP_BASED_LOOP
//
// Following method allows you to specify explicit time limit for OS to process
// events. Though it might lend you best rendering performance some input events
// maybe missing, therefore you must carefully tweak
// kMillisecondsPerFrameToProcessEvents to achieve desired responsivness.
//
// Constants supported by this method: kMillisecondsPerFrameToProcessEvents, kFPS


// Constants:
//
// kFPS - allows you to set desired framerate in frames per second. Set to 30 by
// default. Normally game will not run faster than specified by kFPS. Note that
// iPhone device can not render faster than 60 frames per second.

// kThrottleFPS - usually you need to boost NSTimer approach a bit to get any
// decent performance. Set to 2 by default. Meaningful only if
// NSTIMER_BASED_LOOP method is used.

// kMillisecondsPerFrameToProcessEvents - allows you to specify how much time
// you allow to process events if OS event pump method is used. Set to 3ms by
// default. Settings kMillisecondsPerFrameToProcessEvents to 0 will make main
// loop to wait for OS to pump all events.
// Meaningful only if EVENT_PUMP_BASED_LOOP method is used.

#define USE_OPENGLES20_IF_AVAILABLE 1
#define USE_DISPLAY_LINK_IF_AVAILABLE 1
// MSAA_DEFAULT_SAMPLE_COUNT was moved to iPhone_GlesSupport.h

//#define FALLBACK_LOOP_TYPE NSTIMER_BASED_LOOP
#define FALLBACK_LOOP_TYPE THREAD_BASED_LOOP
//#define FALLBACK_LOOP_TYPE EVENT_PUMP_BASED_LOOP


#include "iPhone_Common.h"
#include "iPhone_GlesSupport.h"

// ENABLE_INTERNAL_PROFILER and related defines were moved to iPhone_Profiler.h
#include "iPhone_Profiler.h"


// --- CONSTANTS ---------------------------------------------------------------
//

#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
#define kThrottleFPS							2.0
#endif

#if FALLBACK_LOOP_TYPE == EVENT_PUMP_BASED_LOOP
#define kMillisecondsPerFrameToProcessEvents	3
#endif

#define kFPS									30.0
#define kAccelerometerFrequency					60.0

// Time to process events in seconds.
// Only used when display link loop is enabled.
#define kInputProcessingTime					0.001


// --- Unity -------------------------------------------------------------------
//

enum EnabledOrientation
{
	kAutorotateToPortrait = 1,
	kAutorotateToPortraitUpsideDown = 2,
	kAutorotateToLandscapeLeft = 4,
	kAutorotateToLandscapeRight = 8
};


enum ScreenOrientation
{
	kScreenOrientationUnknown,
	portrait,
	portraitUpsideDown,
	landscapeLeft,
	landscapeRight,
	autorotation,
	kScreenOrientationCount
};


void UnityPlayerLoop();
void UnityFinishRendering();
void UnityInitApplication(const char* appPathName);
void UnityPause(bool pause);
void UnityReloadResources();
void UnitySetAudioSessionActive(bool active);
void UnityCleanup();

void UnitySendTouchesBegin(NSSet* touches, UIEvent* event);
void UnitySendTouchesEnded(NSSet* touches, UIEvent* event);
void UnitySendTouchesCancelled(NSSet* touches, UIEvent* event);
void UnitySendTouchesMoved(NSSet* touches, UIEvent* event);
void UnityDidAccelerate(float x, float y, float z, NSTimeInterval timestamp);
void UnityInputProcess();
bool UnityIsRenderingAPISupported(int renderingApi);
void UnitySetInputScaleFactor(float scale);
float UnityGetInputScaleFactor();

bool UnityIsOrientationEnabled(EnabledOrientation orientation);
void UnitySetScreenOrientation(ScreenOrientation orientation);
ScreenOrientation UnityRequestedScreenOrientation();
//ScreenOrientation ConvertToUnityScreenOrientation(UIInterfaceOrientation hwOrient, EnabledOrientation* outAutorotOrient);
bool UnityUseOSAutorotation();

bool UnityUse32bitDisplayBuffer();

void	UnityKeyboardOrientationStep1();
void	UnityKeyboardOrientationStep2();

int 	UnityGetDesiredMSAASampleCount(int defaultSampleCount);

enum TargetResolution
{
    kTargetResolutionNative = 0,
    kTargetResolutionStandard = 1,
    kTargetResolutionHD = 2
};

int UnityGetTargetResolution();


static UIViewController *sGLViewController = nil;

UIViewController *UnityGetGLViewController()
{
	return sGLViewController;
}


bool	_ios30orNewer		= false;
bool	_ios31orNewer		= false;
bool	_ios43orNewer		= false;

bool	_supportsDiscard	= false;
bool	_supportsMSAA 		= false;

EAGLSurfaceDesc	_surface;



ScreenOrientation	_curOrientation			= portrait;
ScreenOrientation	_autorotOrientation		= kScreenOrientationUnknown;
bool				_autorotEnableHandling	= false;
bool				_glesContextCreated		= false;
bool				_skipPresent			= false;
bool				_allowOrientationDetection = false;

void UnitySetAllowOrientationDetection(bool allow)
{
	_allowOrientationDetection = allow;
}


class KeyboardOnScreen
{
public:
	static void Init();
};


// --- OpenGLES --------------------------------------------------------------------
//



//extern GLint gDefaultGLES2FBO;
extern GLint gDefaultFBO;


// Forward declaration of CADisplayLink for pre-3.1 SDKS
@interface NSObject(CADisplayLink)
+ (id) displayLinkWithTarget:(id)arg1 selector:(SEL)arg2;
- (void) addToRunLoop:(id)arg1 forMode:(id)arg2;
- (void) setFrameInterval:(int)interval;
- (void) invalidate;
@end


typedef EAGLContext*	MyEAGLContext;

@interface EAGLView : UIView {}
@end

@interface UnityViewController : UIViewController {}
@end


MyEAGLContext			_context;
UIWindow *				_window;
NSTimer*				_timer;
id						_displayLink;
BOOL					_accelerometerIsActive = NO;
// This is set to true when applicationWillResignActive gets called. It is here
// to prevent calling SetPause(false) from applicationDidBecomeActive without
// previous call to applicationWillResignActive
BOOL					_didResignActive = NO;

bool CreateSurface(EAGLView *view, EAGLSurfaceDesc* surface);
void DestroySurface(EAGLSurfaceDesc* surface);

bool CreateWindowSurface(EAGLView *view, GLuint format, GLuint depthFormat, GLuint msaaSamples, bool retained, EAGLSurfaceDesc* surface)
{

    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)[view layer];

	surface->format = format;
	surface->depthFormat = depthFormat;

	surface->depthbuffer = 0;
	surface->renderbuffer = 0;
	surface->framebuffer = 0;

	surface->msaaFramebuffer = 0;
	surface->msaaRenderbuffer = 0;
	surface->msaaDepthbuffer = 0;
	surface->msaaSamples = msaaSamples;

	const NSString* colorFormat = UnityUse32bitDisplayBuffer() ? kEAGLColorFormatRGBA8 : kEAGLColorFormatRGB565;

	eaglLayer.opaque = YES;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, colorFormat, kEAGLDrawablePropertyColorFormat, nil];


	return CreateSurface(view, &_surface);
}


extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglLayer)
{
	return [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)eaglLayer];
}

bool CreateSurface(EAGLView *view, EAGLSurfaceDesc* surface)
{
	CAEAGLLayer* eaglLayer = (CAEAGLLayer*)[view layer];

	CGSize newSize = [eaglLayer bounds].size;
	newSize.width  = roundf(newSize.width);
	newSize.height = roundf(newSize.height);

#ifdef __IPHONE_4_0
    int resolution = UnityGetTargetResolution();

    if (resolution == kTargetResolutionNative ||
        resolution == kTargetResolutionHD)
    {
        if ([view respondsToSelector:@selector(setContentScaleFactor:)])
        {
            UIScreen* mainScreen = [UIScreen mainScreen];
            CGFloat scaleFactor = mainScreen.scale;
            [view setContentScaleFactor:scaleFactor];
            newSize.width = roundf(newSize.width * scaleFactor);
            newSize.height = roundf(newSize.height * scaleFactor);
            UnitySetInputScaleFactor(scaleFactor);
        }
    }
#endif

	surface->w = newSize.width;
	surface->h = newSize.height;

	UNITY_DBG_LOG ("CreateWindowSurface: create non-AA FBO\n");
	CreateSurfaceGLES(surface, eaglLayer);

	if (!_supportsMSAA)
		surface->msaaSamples = 0;

	CreateSurfaceMultisampleBuffersGLES(surface);

	GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->renderbuffer) );

	return true;
}


void DestroySurface(EAGLSurfaceDesc* surface)
{
	EAGLContext *oldContext = [EAGLContext currentContext];

	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];

	UnityFinishRendering();
	DestroySurfaceGLES(surface);

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

void PresentSurface(EAGLSurfaceDesc* surface)
{
	if(_skipPresent)
	{
		UNITY_DBG_LOG ("SKIP PresentSurface:\n");
		return;
	}
	UNITY_DBG_LOG ("PresentSurface:\n");

	EAGLContext *oldContext = [EAGLContext currentContext];
	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];

	PreparePresentSurfaceGLES(surface);

	// presentRenderbuffer presents currently bound RB, so make sure we have the correct one bound
	GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->renderbuffer) );
	if(![_context presentRenderbuffer:GL_RENDERBUFFER_OES])
		printf_console("failed to present renderbuffer (%s:%i)\n", __FILE__, __LINE__ );

	AfterPresentSurfaceGLES(surface);

	if(oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

void PresentContext_UnityCallback(struct UnityFrameStats const* unityFrameStats)
{
	Profiler_FrameEnd();

	PresentSurface(&_surface);

	Profiler_FrameUpdate(unityFrameStats);
	Profiler_FrameStart();
}


int OpenEAGL_UnityCallback(UIWindow** window, int* screenWidth, int* screenHeight,  int* openglesVersion)
{
	CGRect rect = [[UIScreen mainScreen] bounds];

	// Create a full-screen window
	_window = [[UIWindow alloc] initWithFrame:rect];
	EAGLView* view = [[EAGLView alloc] initWithFrame:rect];
	UnityViewController *controller = [[UnityViewController alloc] init];
	sGLViewController = controller;

#if defined(__IPHONE_3_0)
	if( _ios30orNewer )
		controller.wantsFullScreenLayout = TRUE;
#endif

	controller.view = view;
	[_window addSubview:view];


	if( !UnityUseOSAutorotation() )
	{
		_autorotEnableHandling = true;
		[[NSNotificationCenter defaultCenter] postNotificationName: UIDeviceOrientationDidChangeNotification object: [UIDevice currentDevice]];
	}

	int openglesApi =
#if defined(__IPHONE_3_0) && USE_OPENGLES20_IF_AVAILABLE
	kEAGLRenderingAPIOpenGLES2;
#else
	kEAGLRenderingAPIOpenGLES1;
#endif

	for (; openglesApi >= kEAGLRenderingAPIOpenGLES1 && !_context; --openglesApi)
	{
		if (!UnityIsRenderingAPISupported(openglesApi))
			continue;

		_context = [[EAGLContext alloc] initWithAPI:openglesApi];
	}

	if (!_context)
		return false;

	if (![EAGLContext setCurrentContext:_context]) {
		_context = 0;
		return false;
	}

	const GLuint colorFormat = UnityUse32bitDisplayBuffer() ? GL_RGBA8_OES : GL_RGB565_OES;

	if (!CreateWindowSurface(view, colorFormat, GL_DEPTH_COMPONENT16_OES, UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT), NO, &_surface)) {
		return false;
	}

	glViewport(0, 0, _surface.w, _surface.h);
	[_window makeKeyAndVisible];
	[view release];

	*window = _window;
	*screenWidth = _surface.w;
	*screenHeight = _surface.h;
	*openglesVersion = _context.API;

	_glesContextCreated = true;

	return true;
}

UIInterfaceOrientation
ConvertToIosScreenOrientation(ScreenOrientation orient)
{
	switch( orient )
	{
		case portrait:				return UIInterfaceOrientationPortrait;
		case portraitUpsideDown:	return UIInterfaceOrientationPortraitUpsideDown;
		// landscape left/right have switched values in device/screen orientation
		// though unity docs are adjusted with device orientation values, so swap here
		case landscapeLeft:			return UIInterfaceOrientationLandscapeRight;
		case landscapeRight:		return UIInterfaceOrientationLandscapeLeft;
	}

	return UIInterfaceOrientationPortrait;
}

bool
OrientationWillChangeSurfaceExtents( ScreenOrientation prevOrient, ScreenOrientation targetOrient )
{
	bool prevLandscape   = ( prevOrient == landscapeLeft || prevOrient == landscapeRight );
	bool targetLandscape = ( targetOrient == landscapeLeft || targetOrient == landscapeRight );

	return( prevLandscape != targetLandscape );
}

CGAffineTransform TransformForOrientation( ScreenOrientation orient )
{
	static CGAffineTransform	transform[kScreenOrientationCount];
	static bool					inited = false;

	if( !inited )
	{
		transform[portrait]				= CGAffineTransformIdentity;
		transform[portraitUpsideDown]	= CGAffineTransformMakeRotation(M_PI);
		transform[landscapeLeft]		= CGAffineTransformMakeRotation(M_PI_2);
		transform[landscapeRight]		= CGAffineTransformMakeRotation(-M_PI_2);

		inited = true;
	}

	return transform[orient];
}

CGRect ContentRectForOrientation( ScreenOrientation orient )
{
	static CGRect	contentRect[kScreenOrientationCount];
	static bool		inited = false;

	if( !inited )
	{
		CGRect screenRect		= [[UIScreen mainScreen] bounds];
		CGRect flipScreenRect	= CGRectMake(screenRect.origin.y, screenRect.origin.x, screenRect.size.height, screenRect.size.width);

		contentRect[portrait]			= screenRect;
		contentRect[portraitUpsideDown]	= screenRect;
		contentRect[landscapeLeft]		= flipScreenRect;
		contentRect[landscapeRight]		= flipScreenRect;

		inited = true;
	}

	return contentRect[orient];
}

bool
ShouldHandleRotation( ScreenOrientation* outTargetOrient )
{
	ScreenOrientation requestedOrient	= UnityRequestedScreenOrientation();
	ScreenOrientation targetOrient		= requestedOrient == autorotation ? _autorotOrientation : requestedOrient;

	if( outTargetOrient )
		*outTargetOrient = targetOrient;

	return targetOrient != kScreenOrientationUnknown && targetOrient != _curOrientation;
}

void
HandleOrientationRequest()
{
	UnityViewController*	controller	= (UnityViewController*)UnityGetGLViewController();
	EAGLView*				view		= (EAGLView*)[controller view];

	ScreenOrientation targetOrient = portrait;
	if( ShouldHandleRotation(&targetOrient) )
	{
		UnityFinishRendering();

		[CATransaction begin];

		UnityKeyboardOrientationStep1();
		view.transform	= TransformForOrientation(targetOrient);
		view.bounds		= ContentRectForOrientation(targetOrient);

		[UIApplication sharedApplication].statusBarOrientation = ConvertToIosScreenOrientation(targetOrient);

		UnitySetScreenOrientation(targetOrient);
		if( OrientationWillChangeSurfaceExtents(_curOrientation, targetOrient) )
		{
			DestroySurface(&_surface);
			CreateSurface(view, &_surface);

			// seems like ios sometimes got confused about abrupt swap chain destroy
			// draw 2 times to fill both buffers
			// present only once to make sure correct image goes to CA
			_skipPresent = true;
			{
				UnityPlayerLoop();
				UnityPlayerLoop();
				UnityFinishRendering();
			}
			_skipPresent = false;

			PresentSurface(&_surface);
		}
		[CATransaction commit];

		[CATransaction begin];
		UnityKeyboardOrientationStep2();
		[CATransaction commit];

		_curOrientation = targetOrient;
	}
}



// --- AppController --------------------------------------------------------------------
//


@implementation AppController

- (void) registerAccelerometer
{
	// NOTE: work-around for accelerometer sometimes failing to register (presumably on older devices)
	// set accelerometer delegate to nil first
	// work-around reported by Brian Robbins

	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];

	if (kAccelerometerFrequency > 1e-6)
	{
		const float accelerometerFrequency = kAccelerometerFrequency;
		[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / accelerometerFrequency)];
		[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	}
}

- (void) RepaintDisplayLink
{
#if USE_DISPLAY_LINK_IF_AVAILABLE
	[_displayLink setPaused: YES];

	while (CFRunLoopRunInMode(kCFRunLoopDefaultMode, kInputProcessingTime, TRUE) == kCFRunLoopRunHandledSource)
		;

	[_displayLink setPaused: NO];
	[self Repaint];
#endif
}

- (void) Repaint
{
	Profiler_UnityLoopStart();

	UnityInputProcess();
	UnityPlayerLoop();

	Profiler_UnityLoopEnd();

	// TODO: maybe repaint is not the best place?
	HandleOrientationRequest();

	if (kAccelerometerFrequency > 1e-6 && (!_accelerometerIsActive || ([UIAccelerometer sharedAccelerometer].delegate == nil)))
	{
		static int frameCounter = 0;
		if (frameCounter <= 0)
		{
			// NOTE: work-around for accelerometer sometimes failing to register (presumably on older devices)
			// sometimes even Brian Robbins work-around doesn't help
			// then we will try to register accelerometer every N frames until we succeed

			printf_console("-> force accelerometer registration\n");
			[self registerAccelerometer];
			frameCounter = 90; // try every ~3 seconds
		}
		--frameCounter;
	}
}

- (void) startRendering:(UIApplication*)application
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if FALLBACK_LOOP_TYPE == THREAD_BASED_LOOP
	const double SecondsPerFrame = 1.0 / (((kFPS) > 60.0)? 60.0: (kFPS));
	const double OneMillisecond = 1.0 / 1000.0;
	for (;;)
	{
		double frameStartTime = (double)CFAbsoluteTimeGetCurrent();
		[self performSelectorOnMainThread:@selector(Repaint) withObject:nil waitUntilDone:YES];

		double secondsToProcessEvents = SecondsPerFrame - (((double)CFAbsoluteTimeGetCurrent()) - frameStartTime);
		// if we run considerably slower than desired framerate anyhow
		// then we should sleep for a while leaving OS some room to process events
		if (secondsToProcessEvents < -OneMillisecond)
			secondsToProcessEvents = OneMillisecond;
		if (secondsToProcessEvents > 0)
			[NSThread sleepForTimeInterval:secondsToProcessEvents];
	}

#elif FALLBACK_LOOP_TYPE == EVENT_PUMP_BASED_LOOP

	int eventLoopTimeOuts = 0;
	const double SecondsPerFrameToProcessEvents = 0.001 * (double)kMillisecondsPerFrameToProcessEvents;
	const double SecondsPerFrame = 1.0 / (((kFPS) > 60.0)? 60.0: (kFPS));
	for (;;)
	{
		double frameStartTime = (double)CFAbsoluteTimeGetCurrent();
		[self Repaint];

		if (kMillisecondsPerFrameToProcessEvents <= 0)
		{
			while(CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, TRUE) == kCFRunLoopRunHandledSource);
		}
		else
		{
			double secondsToProcessEvents = SecondsPerFrame - (((double)CFAbsoluteTimeGetCurrent()) - frameStartTime);
			if(secondsToProcessEvents < SecondsPerFrameToProcessEvents)
				secondsToProcessEvents = SecondsPerFrameToProcessEvents;

			if (CFRunLoopRunInMode(kCFRunLoopDefaultMode, secondsToProcessEvents, FALSE) == kCFRunLoopRunTimedOut)
				++eventLoopTimeOuts;
		}
	}

#endif
	[pool release];
}

- (void) startUnity:(UIApplication*)application
{
	if( [ [[UIDevice currentDevice] systemVersion] compare: @"3.0" options: NSNumericSearch ] != NSOrderedAscending )
		_ios30orNewer = true;

	if( [ [[UIDevice currentDevice] systemVersion] compare: @"3.1" options: NSNumericSearch ] != NSOrderedAscending )
		_ios31orNewer = true;

	if( [ [[UIDevice currentDevice] systemVersion] compare: @"4.3" options: NSNumericSearch ] != NSOrderedAscending )
		_ios43orNewer = true;

	char const* appPath = [[[NSBundle mainBundle] bundlePath]UTF8String];
	UnityInitApplication(appPath);
	Profiler_InitProfiler();
	InitGLES();

	_displayLink = nil;
#if USE_DISPLAY_LINK_IF_AVAILABLE
	// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
	// class is used as fallback when it isn't available.
	if (_ios31orNewer)
	{
		// Frame interval defines how many display frames must pass between each time the
		// display link fires.
		int animationFrameInterval = (60.0 / (kFPS));
		if (animationFrameInterval < 1)
			animationFrameInterval = 1;

		_displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(RepaintDisplayLink)];
		[_displayLink setFrameInterval:animationFrameInterval];
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	}
#endif

	if (_displayLink == nil)
	{
#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
		_timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / (kFPS * kThrottleFPS)) target:self selector:@selector(Repaint) userInfo:nil repeats:YES];
#endif
	}

	[self registerAccelerometer];

	KeyboardOnScreen::Init();

	if (_displayLink == nil)
	{
#if FALLBACK_LOOP_TYPE == THREAD_BASED_LOOP
		[NSThread detachNewThreadSelector:@selector(startRendering:) toTarget:self withObject:nil];
#elif FALLBACK_LOOP_TYPE == EVENT_PUMP_BASED_LOOP
		[self performSelectorOnMainThread:@selector(startRendering:) withObject:application waitUntilDone:NO];
#endif
	}

	// immediately render 1st frame in order to avoid occasional black screen
	// we do it twice to fill both buffers with meaningful contents.
	// set proper orientation right away?
	[self Repaint];
	[self Repaint];
}

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	//	Initialize Crittercism so we can see unity startup crashes
	Crittercism_EnableWithAppID(kCrittercism_App);
	
	printf_console("-> applicationDidFinishLaunching()\n");

	if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == NO)
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

	[self startUnity:application];
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
}

- (void) applicationDidBecomeActive:(UIApplication*)application
{
	printf_console("-> applicationDidBecomeActive()\n");
	if (_didResignActive)
	{
		UnityPause(false);
	}

	_didResignActive = NO;
}

- (void) applicationWillResignActive:(UIApplication*)application
{
	printf_console("-> applicationDidResignActive()\n");
	UnityPause(true);

	_didResignActive = YES;
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	printf_console("WARNING -> applicationDidReceiveMemoryWarning()\n");
}

- (void) applicationWillTerminate:(UIApplication*)application
{
	printf_console("-> applicationWillTerminate()\n");

	Profiler_UninitProfiler();

	UnityCleanup();
}

- (void) dealloc
{
	DestroySurface(&_surface);
	[_context release];
	_context = nil;

	[_window release];
	[super dealloc];
}

- (void) accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration
{
	UnityDidAccelerate(acceleration.x, acceleration.y, acceleration.z, acceleration.timestamp);
	_accelerometerIsActive = YES;
}

@end

@implementation UnityViewController
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//	EnabledOrientation targetAutorot   = kAutorotateToPortrait;
    //TODO:FIX
//	ScreenOrientation  targetOrient    = ConvertToUnityScreenOrientation(interfaceOrientation, &targetAutorot);
//	ScreenOrientation  requestedOrientation = UnityRequestedScreenOrientation();
//
//	if (requestedOrientation != autorotation)
//		return (requestedOrientation == targetOrient);
//
//	if (UnityIsOrientationEnabled(targetAutorot))
//	{
//		_autorotOrientation = targetOrient;
//
//		if (_allowOrientationDetection)
//		{
//			return true;
//		}
//
//		if (UnityUseOSAutorotation() || !_autorotEnableHandling)
//		{
//			return true;
//		}
//	}

	return false;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //TODO:Fix
	//_curOrientation = ConvertToUnityScreenOrientation(toInterfaceOrientation, 0);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	UnitySetScreenOrientation(_curOrientation);
    //TODO:Fix
	ScreenOrientation prevOrientation = _curOrientation;//ConvertToUnityScreenOrientation(fromInterfaceOrientation, 0);

	if( OrientationWillChangeSurfaceExtents(prevOrientation, _curOrientation) || _allowOrientationDetection )
	{
		if( _glesContextCreated )
		{
			DestroySurface(&_surface);
			CreateSurface([self view], &_surface);
		}
	}

	UnitySetAllowOrientationDetection(false);
}

@end

@implementation EAGLView

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		[self setMultipleTouchEnabled:YES];
		[self setExclusiveTouch:YES];
	}
	return self;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesBegin(touches, event);
}
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesEnded(touches, event);
}
- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesCancelled(touches, event);
}
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	UnitySendTouchesMoved(touches, event);
}

@end
