#import "AppController.h"
#import "iPhone_Sensors.h"

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


// Fallback types (for pre 3.1 devices):

// NSTIMER_BASED_LOOP
//
// It is a common approach to use NSTimer for scheduling rendering on a pre 3.1
// device NSTimer approach is perfect for non-performance critical applications
// which favours battery life and scrupulous correct events processing over the
// rendering performance.
//
// Constants supported by this method: kThrottleFPS


// THREAD_BASED_LOOP
//
// However number of games might prefer frame-rate over battery life,
// therefore Unity provide alternate methods which allows you to run in a
// tighter rendering loop.

// Thread based loop allows to get best of two worlds - fast rendering and
// guaranteed event processing.
//


// EVENT_PUMP_BASED_LOOP
//
// Following method allows you to specify explicit time limit for OS to process
// events. Though it might lend you best rendering performance some input events
// maybe missing, therefore you must carefully tweak
// kMillisecondsPerFrameToProcessEvents to achieve desired responsivness.
//
// Constants supported by this method: kMillisecondsPerFrameToProcessEvents


// Constants:
//
// kThrottleFPS - usually you need to boost NSTimer approach a bit to get any
// decent performance. Set to 2 by default. Meaningful only if
// NSTIMER_BASED_LOOP method is used.

// kMillisecondsPerFrameToProcessEvents - allows you to specify how much time
// you allow to process events if OS event pump method is used. Set to 3ms by
// default. Settings kMillisecondsPerFrameToProcessEvents to 0 will make main
// loop to wait for OS to pump all events.
// Meaningful only if EVENT_PUMP_BASED_LOOP method is used.

#define USE_DISPLAY_LINK_IF_AVAILABLE 1
// MSAA_DEFAULT_SAMPLE_COUNT was moved to iPhone_GlesSupport.h

//#define FALLBACK_LOOP_TYPE NSTIMER_BASED_LOOP
#define FALLBACK_LOOP_TYPE THREAD_BASED_LOOP
//#define FALLBACK_LOOP_TYPE EVENT_PUMP_BASED_LOOP

#include "iPhone_Common.h"
#include "iPhone_OrientationSupport.h"
#include "iPhone_GlesSupport.h"

// ENABLE_INTERNAL_PROFILER and related defines were moved to iPhone_Profiler.h
#include "iPhone_Profiler.h"

#include "iPhone_View.h"


// --- CONSTANTS ---------------------------------------------------------------
//

#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
#define kThrottleFPS                            2.0
#endif

#if FALLBACK_LOOP_TYPE == EVENT_PUMP_BASED_LOOP
#define kMillisecondsPerFrameToProcessEvents    3
#endif

// kFPS define for removed
// you can use Application.targetFrameRate (30 fps by default)

// Time to process events in seconds.
// Only used when display link loop is enabled.
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
bool UnityIsRenderingAPISupported(int renderingApi);
void UnitySetInputScaleFactor(float scale);
float UnityGetInputScaleFactor();
int  UnityGetTargetFPS();

bool UnityUse32bitDisplayBuffer();

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

bool    _ios30orNewer       = false;
bool    _ios31orNewer       = false;
bool    _ios43orNewer       = false;
bool    _ios50orNewer       = false;
bool    _ios60orNewer       = false;

bool    _supportsDiscard    = false;
bool    _supportsMSAA       = false;

EAGLSurfaceDesc _surface;

bool    _glesContextCreated = false;
bool    _unityLevelReady    = false;
bool    _skipPresent        = false;
bool    _recreateSurface    = false;

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


typedef EAGLContext*    MyEAGLContext;


MyEAGLContext           _context;

NSTimer*                _timer;
bool                    _need_recreate_timer = false;
id                      _displayLink;
// This is set to true when applicationWillResignActive gets called. It is here
// to prevent calling SetPause(false) from applicationDidBecomeActive without
// previous call to applicationWillResignActive
BOOL                    _didResignActive = NO;

bool CreateSurface(EAGLView *view, EAGLSurfaceDesc* surface);
void DestroySurface(EAGLSurfaceDesc* surface);

bool CreateWindowSurface(EAGLView *view, GLuint format, GLuint depthFormat, GLuint msaaSamples, bool retained, EAGLSurfaceDesc* surface)
{
    ::memset(surface, 0x00, sizeof(EAGLSurfaceDesc));
    surface->eaglLayer = (CAEAGLLayer*)[view layer];

    surface->format = format;
    surface->depthFormat = depthFormat;
    surface->msaaSamples = _supportsMSAA ? msaaSamples : 0;

    surface->systemFramebuffer  = 0;
    surface->systemRenderbuffer = 0;

    surface->targetFramebuffer  = 0;
    surface->targetRT           = 0;

    surface->msaaFramebuffer    = 0;
    surface->msaaRenderbuffer   = 0;

    surface->depthbuffer        = 0;

    surface->systemW = surface->systemH = 0;
    surface->targetW = surface->targetH = 0;

    surface->use32bitColor = UnityUse32bitDisplayBuffer();

    return CreateSurface(view, &_surface);
}

extern "C" void InitEAGLLayer(void* eaglLayer, bool use32bitColor)
{
    CAEAGLLayer* layer = (CAEAGLLayer*)eaglLayer;

    const NSString* colorFormat = use32bitColor ? kEAGLColorFormatRGBA8 : kEAGLColorFormatRGB565;

    layer.opaque = YES;
    layer.drawableProperties =  [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                    colorFormat, kEAGLDrawablePropertyColorFormat,
                                    nil
                                ];
}
extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglLayer)
{
    return [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)eaglLayer];
}
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer()
{
    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:nil];
}

static void
SetupTargetResolution(EAGLSurfaceDesc* surface)
{
    // while this may look stupid, we call that function from inside unity render loop
    // so dont fiddle with resoltion right away, but postpone till the end of the frame
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

    unsigned targetW = surface->systemW;
    unsigned targetH = surface->systemH;

    switch( targetRes )
    {
        case kTargetResolution320p:
            targetW = 320;
            targetH = 480;
            break;

        case kTargetResolution640p:
            targetW = 640;
            targetH = 960;
            break;

        case kTargetResolution768p:
            targetW = 768;
            targetH = 1024;
            break;

        case kTargetResolutionAutoPerformance:
        case kTargetResolutionAutoQuality:
            targetW = surface->systemW * resMult;
            targetH = surface->systemH * resMult;
            break;
    }

    surface->targetW = targetW;
    surface->targetH = targetH;
}


bool CreateSurface(EAGLView *view, EAGLSurfaceDesc* surface)
{
    CAEAGLLayer* eaglLayer = (CAEAGLLayer*)surface->eaglLayer;
    assert(eaglLayer == [view layer]);

    CGSize newSize = [eaglLayer bounds].size;
    newSize.width  = roundf(newSize.width) * ScreenScaleFactor();
    newSize.height = roundf(newSize.height) * ScreenScaleFactor();
    UnitySetInputScaleFactor(ScreenScaleFactor());

    surface->systemW = (unsigned)newSize.width;
    surface->systemH = (unsigned)newSize.height;

    // if we recreate surface due to orientation change we don't want to tweak resolution
    if( surface->targetW == 0 || surface->targetH == 0 )
        SetupTargetResolution(surface);

    CreateSurfaceGLES(surface);
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
    if(_skipPresent || _didResignActive)
    {
        UNITY_DBG_LOG ("SKIP PresentSurface %s\n", _didResignActive ? "due to going to background":"");
        return;
    }
    UNITY_DBG_LOG ("PresentSurface:\n");

    EAGLContext *oldContext = [EAGLContext currentContext];
    if (oldContext != _context)
        [EAGLContext setCurrentContext:_context];

    PreparePresentSurfaceGLES(surface);

    // presentRenderbuffer presents currently bound RB, so make sure we have the correct one bound
    GLES_CHK( glBindRenderbufferOES(GL_RENDERBUFFER_OES, surface->systemRenderbuffer) );
    if(![_context presentRenderbuffer:GL_RENDERBUFFER_OES])
        printf_console("failed to present renderbuffer (%s:%i)\n", __FILE__, __LINE__ );

    AfterPresentSurfaceGLES(surface);

    if(oldContext != _context)
        [EAGLContext setCurrentContext:oldContext];
}

void RecreateSurface(EAGLSurfaceDesc* surface, bool insideRepaint)
{
    if(_glesContextCreated)
    {
        DestroySurface(surface);
        UnityGetRenderingResolution(&surface->targetW, &surface->targetH);
        CreateSurface((EAGLView*)UnityGetGLView(), surface);

        if(_unityLevelReady)
        {
            // seems like ios sometimes got confused about abrupt swap chain destroy
            // draw 2 times to fill both buffers
            // present only once to make sure correct image goes to CA
            // if we are inside Repaint redraw only once without present - second one will be done in Reapoint itself
            _skipPresent = true;
            {
                UnityPlayerLoop();
                if(!insideRepaint)
                    UnityPlayerLoop();
                UnityFinishRendering();
            }
            _skipPresent = false;
            if(!insideRepaint)
                PresentSurface(&_surface);
        }
    }
}

void PresentContext_UnityCallback(struct UnityFrameStats const* unityFrameStats)
{
    Profiler_FrameEnd();
    PresentSurface(&_surface);
    Profiler_FrameUpdate(unityFrameStats);
}


int OpenEAGL_UnityCallback(UIWindow** window, int* screenWidth, int* screenHeight,  int* openglesVersion)
{
    // TODO: in splash do use info.plist values and push creation earlier
    CreateViewHierarchy();

    for (int openglesApi = kEAGLRenderingAPIOpenGLES2 ; openglesApi >= kEAGLRenderingAPIOpenGLES1 && !_context ; --openglesApi)
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

    if( !CreateWindowSurface( (EAGLView*)UnityGetGLView(), colorFormat, GL_DEPTH_COMPONENT16_OES,
                              UnityGetDesiredMSAASampleCount(MSAA_DEFAULT_SAMPLE_COUNT), NO, &_surface
                            )
      )
    {
        return false;
    }

    glViewport(0, 0, _surface.targetW, _surface.targetH);

    *window = UnityGetMainWindow();
    *screenWidth = _surface.targetW;
    *screenHeight = _surface.targetH;
    *openglesVersion = _context.API;

    _glesContextCreated = true;

    return true;
}

void NotifyFramerateChange(int targetFPS)
{
    if( targetFPS <= 0 )
        targetFPS = 60;

#if USE_DISPLAY_LINK_IF_AVAILABLE
    if (_displayLink)
    {
        int animationFrameInterval = (60.0 / (targetFPS));
        if (animationFrameInterval < 1)
            animationFrameInterval = 1;

        [_displayLink setFrameInterval:animationFrameInterval];
    }
#endif
#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
    if (_displayLink == 0 && _timer)
        _need_recreate_timer = true;
#endif
}



// --- AppController --------------------------------------------------------------------
//


@implementation AppController

- (void) RepaintDisplayLink
{
#if USE_DISPLAY_LINK_IF_AVAILABLE
    [_displayLink setPaused: YES];

    static const CFStringRef kTrackingRunLoopMode = CFStringRef(UITrackingRunLoopMode);
    while (CFRunLoopRunInMode(kTrackingRunLoopMode, kInputProcessingTime, TRUE) == kCFRunLoopRunHandledSource)
        ;

    [_displayLink setPaused: NO];
    [self Repaint];
#endif
}

- (void) Repaint
{
    if(_didResignActive)
        return;

    if( _surface.systemRenderbuffer == 0 || _recreateSurface)
    {
        RecreateSurface(&_surface, true);
        _recreateSurface = false;
    }

    Profiler_FrameStart();
    UnityInputProcess();
    UnityPlayerLoop();

    CheckOrientationRequest();

#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
    if (_displayLink == 0 && _timer && _need_recreate_timer)
    {
        [_timer invalidate];
        _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / (UnityGetTargetFPS() * kThrottleFPS)) target:self selector:@selector(Repaint) userInfo:nil repeats:YES];

        _need_recreate_timer = false;
    }
#endif

}

- (void) startRendering
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

#if FALLBACK_LOOP_TYPE == THREAD_BASED_LOOP
    const double OneMillisecond = 1.0 / 1000.0;
    for (;;)
    {
        const double SecondsPerFrame = 1.0 / (float)UnityGetTargetFPS();
        const double frameStartTime  = (double)CFAbsoluteTimeGetCurrent();
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
    for (;;)
    {
        const double SecondsPerFrame = 1.0 / (float)UnityGetTargetFPS();
        const double frameStartTime  = (double)CFAbsoluteTimeGetCurrent();
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

- (void) prepareRunLoop
{
    UnityLoadApplication();
    Profiler_InitProfiler();
    InitGLES();

    _unityLevelReady = true;
    OnUnityReady();

    _displayLink = nil;
#if USE_DISPLAY_LINK_IF_AVAILABLE
    // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
    // class is used as fallback when it isn't available.
    if (_ios31orNewer)
    {
        // Frame interval defines how many display frames must pass between each time the
        // display link fires.
        int animationFrameInterval = 60.0 / (float)UnityGetTargetFPS();
        assert(animationFrameInterval >= 1);

        _displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(RepaintDisplayLink)];
        [_displayLink setFrameInterval:animationFrameInterval];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
#endif

    if (_displayLink == nil)
    {
#if FALLBACK_LOOP_TYPE == NSTIMER_BASED_LOOP
        _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / (UnityGetTargetFPS() * kThrottleFPS)) target:self selector:@selector(Repaint) userInfo:nil repeats:YES];
#endif
    }

    KeyboardOnScreen::Init();

    if (_displayLink == nil)
    {
#if FALLBACK_LOOP_TYPE == THREAD_BASED_LOOP
        [NSThread detachNewThreadSelector:@selector(startRendering) toTarget:self withObject:nil];
#elif FALLBACK_LOOP_TYPE == EVENT_PUMP_BASED_LOOP
        [self performSelectorOnMainThread:@selector(startRendering) withObject:nil waitUntilDone:NO];
#endif
    }

    // immediately render 1st frame in order to avoid occasional black screen
    // we do it twice to fill both buffers with meaningful contents.
    // set proper orientation right away?
    [self Repaint];
    [self Repaint];
}


- (void) startUnity:(UIApplication*)application
{
    if( [ [[UIDevice currentDevice] systemVersion] compare: @"3.0" options: NSNumericSearch ] != NSOrderedAscending )
        _ios30orNewer = true;

    if( [ [[UIDevice currentDevice] systemVersion] compare: @"3.1" options: NSNumericSearch ] != NSOrderedAscending )
        _ios31orNewer = true;

    if( [ [[UIDevice currentDevice] systemVersion] compare: @"4.3" options: NSNumericSearch ] != NSOrderedAscending )
        _ios43orNewer = true;

    if( [ [[UIDevice currentDevice] systemVersion] compare: @"5.0" options: NSNumericSearch ] != NSOrderedAscending )
        _ios50orNewer = true;

    if( [ [[UIDevice currentDevice] systemVersion] compare: @"6.0" options: NSNumericSearch ] != NSOrderedAscending )
        _ios60orNewer = true;

    char const* appPath = [[[NSBundle mainBundle] bundlePath]UTF8String];
    UnityInitApplication(appPath);

    OnUnityStartLoading();
    [self performSelector:@selector(prepareRunLoop) withObject:nil afterDelay:0];
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
    
    //	Initialize Crittercism so we can see unity startup crashes
	Crittercism_EnableWithAppID(kCrittercism_App);
	
    printf_console("-> applicationDidFinishLaunching()\n");
    // get local notification
    if (&UIApplicationLaunchOptionsLocalNotificationKey != nil)
    {
        UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        if (notification)
        {
            UnitySendLocalNotification(notification);
        }
    }

    // get remote notification
    if (&UIApplicationLaunchOptionsRemoteNotificationKey != nil)
    {
        NSDictionary *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notification)
        {
            UnitySendRemoteNotification(notification);
        }
    }

    if ([UIDevice currentDevice].generatesDeviceOrientationNotifications == NO)
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    [self startUnity:application];

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
}

- (void) applicationDidBecomeActive:(UIApplication*)application
{
    printf_console("-> applicationDidBecomeActive()\n");
    if (_didResignActive)
        UnityPause(false);

    _didResignActive = NO;
}

- (void) applicationWillResignActive:(UIApplication*)application
{
    printf_console("-> applicationWillResignActive()\n");
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

	SensorsCleanup();

    ReleaseViewHierarchy();
    [super dealloc];
}
@end


