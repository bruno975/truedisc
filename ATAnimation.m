#import "ATAnimation.h"
#import "ATAnimationGroup.h"

static NSTimeInterval sDefaultRefreshInterval = (1.0 / 30.0);

@interface ATAnimation (Private) 
- (float) progressForTime: (NSTimeInterval) time;
- (void) refresh: (NSTimer*) timer;
- (void) stopRunning;
- (void) startTimer;
- (void) stopTimer;
@end

#pragma mark -

@implementation ATAnimation

- (id) initWithDelegate: (id) obj duration: (NSTimeInterval) secs
{
	if ( self = [super init] ) {
		NSParameterAssert( secs > 0 );
		
		myDuration = secs;
		myRefreshInterval = [[self class] defaultRefreshInterval];
		[self setDelegate:obj];
	}
	return self;
}

- (void) dealloc
{
	[self stopRunning];
	if ( myGroup ) [myGroup removeAnimation:self];
	if ( myUserRef ) [myUserRef release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors & Modifiers

- (id) delegate
{
	return myDelegate;
}

- (void) setDelegate: (id) obj
{
	NSAssert1( !myFlags.isRunning,
		@"-[ATAnimation setDelegate:] invoked while animation was running! - userRef: %@.",
		[myUserRef description] );
	
	myDelegate = obj; // not retained to avoid retain cycles
	if ( myGroup ) [myGroup delegateDidChangeForAnimation:self];
	
		// update delegate flags
	myFlags.delegateRefreshAnimation =
		( obj && [obj respondsToSelector:@selector(refreshAnimation:)] ) ? YES : NO;
	myFlags.delegateAnimationWillStart =
		( obj && [obj respondsToSelector:@selector(animationWillStart:)] ) ? YES : NO;
	myFlags.delegateAnimationDidEnd =
		( obj && [obj respondsToSelector:@selector(animationDidEnd:)] ) ? YES : NO;
	myFlags.delegateAnimationDidStop =
		( obj && [obj respondsToSelector:@selector(animationDidStop:)] ) ? YES : NO;
}

- (NSTimeInterval) duration
{
	return myDuration;
}

- (void) setDuration: (NSTimeInterval) secs
// It's safe to call this while the animation is running.
{
	NSParameterAssert( secs > 0 );
	myDuration = secs;
}

- (NSTimeInterval) refreshInterval
{
	return myRefreshInterval;
}

- (void) setRefreshInterval: (NSTimeInterval) secs
{
	NSParameterAssert( secs > 0 );
	myRefreshInterval = secs;
	
	if ( myTimer ) {
		[self stopTimer];
		[self startTimer];
	}
}

- (id) userRef
{
	return myUserRef;
}

- (void) setUserRef: (id) userRef
{
	if ( myUserRef ) [myUserRef release];
	myUserRef = userRef;
	if ( myUserRef ) [myUserRef retain];
}

- (BOOL) repeats
{
	return myFlags.repeats;
}

- (void) setRepeats: (BOOL) flag
{
	myFlags.repeats = flag ? YES : NO;
}

- (float) progress
{
	return myProgress;
}

- (float) finalProgress
{
	return myFlags.isRunning ? myEndProgress : myProgress;
}

- (void) setProgress: (float) progress
{
	if ( progress < 0.0 ) progress = 0.0;
	if ( progress > 1.0 ) progress = 1.0;
	
	if ( myFlags.isRunning ) [self stop];
	myProgress = progress;
}

+ (NSTimeInterval) defaultRefreshInterval
{
	return sDefaultRefreshInterval;
}

+ (void) setDefaultRefreshInterval: (NSTimeInterval) secs
{
	NSParameterAssert( secs > 0 );
	sDefaultRefreshInterval = secs;
}

#pragma mark -
#pragma mark Animation Control

- (void) run
{
	[self runFrom:0.0 to:1.0];
}

- (void) runBackwards
{
	[self runFrom:1.0 to:0.0];
}

- (void) runFrom: (float) startProgress to: (float) endProgress
{
	NSAssert2( startProgress >= 0.0 && startProgress <= 1.0,
		@"-[ATAnimation runFrom:to:] called with invalid start progress %f (userRef: %@)",
		startProgress, myUserRef );
	NSAssert2( endProgress >= 0.0 && endProgress <= 1.0,
		@"-[ATAnimation runFrom:to:] called with invalid end progress %f (userRef: %@)",
		endProgress, myUserRef );
	
	if ( myFlags.isRunning ) {
			// Animation is already running, so we want to start from the current progress instead of startProgress. However, we cannot set myStartProgress to the current progress and myStartTime to the current time, because if the repeat flag is set, repetitions should start with startProgress. So instead we set myStartTime to the time we would have started at to be at the current progress now (i.e., a time in the past). This is what the following code does. Now we can set myStartProgress to startProgress, but progressForTime: will still return the same progress for the current progress.
			
		float progress = (myProgress - startProgress) / (endProgress - startProgress);
		NSTimeInterval elapsed = myDuration * abs( endProgress - startProgress ) * progress;
		myStartTime = [NSDate timeIntervalSinceReferenceDate] - elapsed;
			// It's important to use myProgress (i.e., the progress refreshAnimation: was invoked with most recently) for the calculation, rather than the progress at the current time. This makes the animation appear much smoother when the direction is reversed, as opposed to re-calculating the progress here.
		
		myStartProgress = startProgress;
		myEndProgress = endProgress;
		
	} else {
		
			// notify delegate
		if ( myFlags.delegateAnimationWillStart ) {
			NS_DURING {
				[myDelegate animationWillStart:self];
			} NS_HANDLER {
				NSLog( @"ATAnimation discarding exception '%@' (reason '%@') that raised during invocation of animationWillStart:. UserRef: %@.", [localException name], [localException reason], [myUserRef description] );
			} NS_ENDHANDLER;
		}
		
		myFlags.isRunning = YES;
		myStartTime = [NSDate timeIntervalSinceReferenceDate];
		myStartProgress = startProgress;
		myEndProgress = endProgress;
		myProgress = myStartProgress;
			// The line above is necessary so the progress method returns a valid progress in the time between now and the first refresh. It also prevents the following tricky problem from happening: If the animation is in a group, and is started by the animationDidEnd: call of another animation in that group, the group's refresh: might call finishRefresh even before beginRefreshWithTime: have ever been called. Now if the animation had run before and myProgress is still the endProgress, it would immediately be stopped again, because beginRefreshWithTime: didn't have a chance to set myProgress.
		
			// create timer to invoke refresh: at regular intervals
		if ( !myGroup ) [self startTimer];
		else [myGroup animationStartedRunning];
	}
}

- (void) runBlocking
{
	[self runBlockingFrom:0.0 to:1.0];
}

- (void) runBackwardsBlocking
{
	[self runBlockingFrom:1.0 to:0.0];
}

- (void) runBlockingFrom: (float) startProgress to: (float) endProgress
{
	NSAssert2( startProgress >= 0.0 && startProgress <= 1.0,
		@"-[ATAnimation runBlockingFrom:to:] called with invalid start progress %f (userRef: %@)",
		startProgress, myUserRef );
	NSAssert2( endProgress >= 0.0 && endProgress <= 1.0,
		@"-[ATAnimation runBlockingFrom:to:] called with invalid end progress %f (userRef: %@)",
		endProgress, myUserRef );
	
		// notify delegate
	if ( myFlags.delegateAnimationWillStart ) {
		NS_DURING {
			[myDelegate animationWillStart:self];
		} NS_HANDLER {
			NSLog( @"ATAnimation discarding exception '%@' (reason '%@') that raised during invocation of animationWillStart:. UserRef: %@.", [localException name], [localException reason], [myUserRef description] );
		} NS_ENDHANDLER;
	}
	
	myFlags.isRunning = YES;
	myStartTime = [NSDate timeIntervalSinceReferenceDate];
	myStartProgress = startProgress;
	myEndProgress = endProgress;
	
	do {
		NSDate* nextRefresh = [NSDate dateWithTimeIntervalSinceNow:myRefreshInterval];
		
		if ( !myGroup ) [self refresh:nil];
		else [myGroup refresh:nil];
		
		[NSThread sleepUntilDate:nextRefresh];
	} while ( myFlags.isRunning );
}

- (BOOL) isRunning
{
	return myFlags.isRunning;
}

- (void) stop
{
	if ( myFlags.isRunning ) {
		myProgress = [self progress];
		[self stopRunning];
		
			// notify delegate
		if ( myFlags.delegateAnimationDidStop ) {
			NS_DURING {
				[myDelegate animationDidStop:(id)self];
			} NS_HANDLER {
				NSLog( @"ATAnimation discarding exception '%@' (reason '%@') that raised during invocation of animationDidStop:. UserRef: %@.", [localException name], [localException reason], [myUserRef description] );
			} NS_ENDHANDLER;
		}
	}
}

@end

#pragma mark -

@implementation ATAnimation (Groups) 

- (void) surrenderControlToGroup: (ATAnimationGroup*) group
// Called by ATAnimationGroup when this animation is added to a group.
// The animation is now run by the group's timer, so we must kill our timer.
{
	NSAssert1( !myGroup,
		@"Animation added to more than one group! - userRef: %@.", [myUserRef description] );
	myGroup = group;
	
	if ( myTimer ) [self stopTimer];
}

- (void) retainControl
// Called by ATAnimationGroup when this animation is removed from a group.
{
	myGroup = nil;
	
	if ( myFlags.isRunning && !myTimer ) {
		[self startTimer];
	}
}

- (void) beginRefreshWithTime: (NSTimeInterval) refreshTime
// Called by refresh: and ATAnimationGroup's refresh:.
{
	myProgress = [self progressForTime:refreshTime];
		// Saving the progress sent to refreshAnimation: (as opposed to calling progressForTime:
		// each time we need the current progress) has four advantages:
		// - It assures finishRefresh gets the same progress as refreshAnimation:.
		// - It allows us to return the last progress for which refreshAnimation: has been
		//   invoked thru the progress method.
		// - For ATViewAnimations, it assures refreshAnimation: and draw: use the same progress.
		// - It assures that all animations in a group are being passed a progress that relates
		//   to the same point of time.
}

- (void) invokeRefreshSelector
// Called by refresh: and ATAnimationGroup's refresh:.
{
	if ( myFlags.delegateRefreshAnimation ) {
		NS_DURING {
			[myDelegate refreshAnimation:self];
		} NS_HANDLER {
			NSLog( @"ATAnimation discarding exception '%@' (reason '%@') that raised during invocation of refreshAnimation:. UserRef: %@.", [localException name], [localException reason], [myUserRef description] );
		} NS_ENDHANDLER;
	}
}

- (void) finishRefresh
// Called by refresh: and ATAnimationGroup's refresh:.
{
	if ( myFlags.isRunning ) { // animation may have been stopped during the call to refreshAnimation:
		if ( myProgress == myEndProgress ) {
			if ( myFlags.repeats ) {
				myStartTime = [NSDate timeIntervalSinceReferenceDate];
			} else {
				[self stopRunning];
				
					// notify delegate
				if ( myFlags.delegateAnimationDidEnd ) {
					NS_DURING {
						[myDelegate animationDidEnd:(id)self];
					} NS_HANDLER {
						NSLog( @"ATAnimation discarding exception '%@' (reason '%@') that raised during invocation of animationDidEnd:. UserRef: %@.", [localException name], [localException reason], [myUserRef description] );
					} NS_ENDHANDLER;
				}
			}
		}
	}
}

@end

#pragma mark -

@implementation ATAnimation (Private)

- (float) progressForTime: (NSTimeInterval) time
{
	NSAssert( myFlags.isRunning,
		@"-[ATAnimation progressForTime:] invoked while animation not running." );
	
	float progress = myStartProgress + (time - myStartTime) / myDuration *
		(myEndProgress - myStartProgress);
	float min = MIN( myStartProgress, myEndProgress );
	float max = MAX( myStartProgress, myEndProgress );
	progress = MAX( progress, min );
	progress = MIN( progress, max );
	return progress;
}

- (void) refresh: (NSTimer*) timer
// Called periodically by the timer, or by runBlocking's loop if run in blocking mode.
{
	[self beginRefreshWithTime:[NSDate timeIntervalSinceReferenceDate]];
	[self invokeRefreshSelector];
	[self finishRefresh];
}

- (void) stopRunning
// The animation did end or has been stopped.
{
	if ( myFlags.isRunning ) {
		myFlags.isRunning = NO;
		
		if ( myTimer ) [self stopTimer];
		else if ( myGroup ) [myGroup animationStoppedRunning];
	}
}

- (void) startTimer
{
	NSAssert( !myTimer, @"-[ATAnimation startTimer] found an exising timer." );
	myTimer = [[NSTimer timerWithTimeInterval:myRefreshInterval target:self
		selector:@selector( refresh: ) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSEventTrackingRunLoopMode];
}

- (void) stopTimer
{
	NSAssert( myTimer, @"-[ATAnimation stopTimer] found no timer." );
	[myTimer invalidate];
	[myTimer release];
	myTimer = nil;
}

@end

#pragma mark -

@implementation ATViewAnimation

- (id) initWithDelegate: (id) obj targetView: (NSView*) view duration: (NSTimeInterval) secs
{
	if ( self = [super initWithDelegate:obj duration:secs] ) {
		myTargetView = view;
		myDrawingRect = NSZeroRect;
	}
	return self;
}

#pragma mark -
#pragma mark Accessors & Modifiers

- (NSView*) targetView
{
	return myTargetView;
}

- (void) setTargetView: (NSView*) view
{
	myTargetView = view;
}

- (BOOL) ignoresOpacity
{
	return myFlags2.ignoresOpacity;
}

- (void) setIgnoresOpacity: (BOOL) flag
{
	myFlags2.ignoresOpacity = flag ? YES : NO;
}

- (void) setDrawingRect: (NSRect) rect
{
	myDrawingRect = rect;
}

- (NSRect) drawingRect
{
	if ( NSEqualRects(myDrawingRect, NSZeroRect) && myTargetView )
		return [myTargetView bounds];
	else return myDrawingRect;
}

#pragma mark -

- (void) refresh: (NSTimer*) timer
// Called periodically by the timer, or by runBlocking's loop if run in blocking mode.
{
	[self beginRefreshWithTime:[NSDate timeIntervalSinceReferenceDate]];
	[self invokeRefreshSelector];
	[self draw];
	[self finishRefresh];
}

- (void) draw
{
	if ( myTargetView ) {
		NS_DURING {
			if ( myFlags2.ignoresOpacity ) [myTargetView displayRectIgnoringOpacity:[self drawingRect]];
			else [myTargetView displayRect:[self drawingRect]];
		} NS_HANDLER {
			NSLog( @"ATViewAnimation discarding exception '%@' (reason '%@') that raised while drawing target view 0x%x. UserRef: %@.", [localException name], [localException reason], myTargetView, [myUserRef description] );
		} NS_ENDHANDLER;
	}
}

@end

#pragma mark -

float ATEaseFunction( float t )
// Stolen from Apple's AnimatedSlider sample:
// "This function implements a sinusoidal ease-in/ease-out for t = 0 to 1.0.  T is scaled to
// represent the interval of one full period of the sine function, and transposed to lie above
// the X axis."
{
	return (sin((t * M_PI) - M_PI_2) + 1.0 ) / 2.0;
}

float ATAccelerationFunction( float t )
{
	return sin( t*M_PI_2 - M_PI_2 ) + 1;
}

float ATBounceFunction( float t )
{
	return sin( t * M_PI );
}



