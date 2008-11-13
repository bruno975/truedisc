// =================================================================================================
//	Animation Toolbox                                                        version 3.0 [June 2006]
// 	
//	 	by Simon HŠrtel
// 		email:   simonhaertel@web.de
// 		website: www.simonhaertel.de.vu
// 
//		See the Read Me file for more information.

#import <Cocoa/Cocoa.h>

@class ATAnimation;
@class ATAnimationGroup;

@interface ATAnimation : NSObject
{
	NSTimeInterval	myDuration;
	NSTimeInterval	myRefreshInterval;
	id				myDelegate;
	id				myUserRef;
	struct {
		unsigned	repeats:1;
		unsigned	isRunning:1;
		unsigned	delegateRefreshAnimation:1;
		unsigned	delegateAnimationWillStart:1;
		unsigned	delegateAnimationDidEnd:1;
		unsigned	delegateAnimationDidStop:1;
	} myFlags;
	NSTimer*		myTimer;
	NSTimeInterval	myStartTime;		// only meaningful while we're running
	float			myStartProgress;	// only meaningful while we're running
	float			myEndProgress;		// only meaningful while we're running
	float			myProgress;		// after running, holds the last progress we had when stopped.
									// While running, holds the progress that was passed to
									// refreshAnimation: on its most recent invocation
	ATAnimationGroup* myGroup;		// nil if we're not in a group
}

- (id) initWithDelegate: (id) obj duration: (NSTimeInterval) secs;


	// -- Accessors & Modifiers --
	
- (id) delegate;
- (void) setDelegate: (id) obj;
	// The delegate is not retained to avoid retain cycles; however, it must stay around until the animation object dies.

- (NSTimeInterval) duration;
- (void) setDuration: (NSTimeInterval) secs;
	// The duration specifies how long it takes to change the animation's progress from 0.0 to 1.0. It's safe to change the duration while the animation is running.

- (NSTimeInterval) refreshInterval;
- (void) setRefreshInterval: (NSTimeInterval) secs;
	// The refresh interval specifies the delay between succeeding invocations of refreshAnimation: on the delegate while the animation runs. Apple recommends refresh rates between 30 and 60 frames per seconds, i.e. refresh intervals between 0.017 and 0.03. Also see defaultRefreshInterval.

- (id) userRef;
- (void) setUserRef: (id) userRef;
	// You can use this for whatever you want, for example, an NSString identifying the animation. The userRef will be retained if non-nil. You can change the userRef at any time.

- (BOOL) repeats;
- (void) setRepeats: (BOOL) flag;
	// The repeat flag determines whether the animation starts again after reaching its final progress (default is NO). If an animation is run with the flag being set, it will keep repeating until it receives a stop message, and not invoke animationDidEnd:. If the repeat flag is set and you run an animation synchronously, you must invoke stop from within refreshAnimation:, or you'll have a perfect infinite loop.

- (float) progress;
	// Returns the last progress refreshAnimation: has been invoked with if the animation is running. If not running, returns the last progress refreshAnimation: has been invoked with before the animation stopped, or, if setProgress had been invoked since then, the progress set by setProgress. Before the animation runs for the first time, the progress is 0.0.

- (float) finalProgress;
	// If the animation is running, returns the progress the animation will have when it will finish (provided it won't be interrupted). If the animation is not running, returns the same as the progress method.

- (void) setProgress: (float) progress;
	// Changes the receiver's progress without running the animation. Stops the animation if it's running.

+ (NSTimeInterval) defaultRefreshInterval;
+ (void) setDefaultRefreshInterval: (NSTimeInterval) secs;
	// The default refresh interval is assigned to all new instances. Often all animations use the same interval, so you may want to set the common refresh interval with this method before creating your animations. Apple recommends refresh rates between 30 and 60 frames per seconds, i.e. refresh intervals between 0.017 and 0.03.


	// -- Animation Control --

- (void) run;
	// Run the animation asynchronously for the time specified by its duration property, with the progress linearly increasing from 0.0 to 1.0. Control returns to the caller immediately, as the animation is driven by an NSTimer. If the animation was already running, it will run from its current progress to 1.0.

- (void) runBackwards;
	// Like run, but change the progress from 1.0 to 0.0.

- (void) runFrom: (float) startProgress to: (float) endProgress;
	// Like run, but the change the progress from startProgress to endProgress. startProgress may be greater than endProgress; however, both must be within [0.0, 1.0]. The speed in which the progress changes is the same as with run, i.e., if startProgress and endProgress make a smaller range than [0.0, 1.0], the animation's duration will be proportionally shorter than the duration specified in the constructor.

- (void) runBlocking;
	// Run the animation synchronously for the time specified by its duration property, with its progress linearly increasing from 0. to 1.0. Control won't return to the caller until the animation has finished. The current thread will be blocked between the invocations to the refresh callback.

- (void) runBackwardsBlocking;
	// Like runBlocking, but change the progress from 1.0 to 0.0.

- (void) runBlockingFrom: (float) startProgress to: (float) endProgress;
	// Same as runBlocking, but the progress changes from startProgress to endProgress. startProgress may be greater than endProgress; however, both must be within [0.0, 1.0]. The speed in which the progress changes is the same as with runBlocking, i.e., if startProgress and endProgress make a smaller range than [0.0, 1.0], the animation's duration will be proportionally shorter than the duration specified in the constructor.

- (BOOL) isRunning;

- (void) stop;
	// Stop the animation, if it's running, without invoking animationDidEnd:. Does nothing if the animation is not running.
@end


	/* The following methods should only invoked by the ATAnimationGroup class,
	   or by the animation object itself. */
@interface ATAnimation (Groups) 
- (void) surrenderControlToGroup: (ATAnimationGroup*) group;
- (void) retainControl;
- (void) beginRefreshWithTime: (NSTimeInterval) refreshTime;
- (void) invokeRefreshSelector;
- (void) finishRefresh;
@end


@interface ATViewAnimation : ATAnimation
{
	NSView*			myTargetView;
	NSRect			myDrawingRect; // NSZeroRect means entire view
	struct {
		unsigned	ignoresOpacity:1;
	} myFlags2;
}

- (id) initWithDelegate: (id) obj targetView: (NSView*) view duration: (NSTimeInterval) secs;


	// -- Accessors & Modifiers --

- (NSView*) targetView;
- (void) setTargetView: (NSView*) view;
	// The target view is not retained to avoid retain cycles; however, it must stay around until the animation object dies.

- (BOOL) ignoresOpacity;
- (void) setIgnoresOpacity: (BOOL) flag;

- (void) setDrawingRect: (NSRect) rect;
- (NSRect) drawingRect;
	// Limits drawing to a certain rect within the target view. Pass NSZeroRect to draw the entire view (the default).
@end


	/* The following method should only invoked by the ATAnimationGroup class,
	   or by the animation object itself. */
@interface ATViewAnimation (Groups) 
- (void) draw;
@end


@interface NSObject (ATAnimationDelegate)
- (void) refreshAnimation: (ATAnimation*) animation;
	// Sent to the delegate in constant time intervals while the animation runs. Used to update the animation's visual representation. Please do not release the animation from within this method.

- (void) animationWillStart: (ATAnimation*) animation;
	// Sent to the delegate before the animation starts running. Can be used to cache an image which is used during the animation, for example.

- (void) animationDidEnd: (ATAnimation*) animation;
	// Sent to the delegate after the animation finished (because it reached its final progress).

- (void) animationDidStop: (ATAnimation*) animation;
	// Sent to the delegate when the animation has been stopped (by sending it a stop or setProgress: message while running).
@end


	// -- Some Goodies ... --

float ATEaseFunction( float t );
float ATAccelerationFunction( float t );
float ATBounceFunction( float t );

