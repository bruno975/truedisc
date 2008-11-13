#import "ATAnimationGroup.h"
#import "ATAnimation.h"
#import <CoreFoundation/CFArray.h>
#import <stdarg.h>

@interface ATAnimationGroup (Private)
- (void) sortAnimations;
- (void) startTimer;
- (void) stopTimer;
@end

@implementation ATAnimationGroup

- (id) init
{
	if ( self = [super init] ) {
	
			// set up the animation array so it does not retain its elements -
			// this works because CFArray and NSArray are "toll-free bridged"
		CFArrayCallBacks arrayCallBacks = {
			0, // version
			NULL, // retain callback
			NULL, // release callback
			kCFTypeArrayCallBacks.copyDescription,
			kCFTypeArrayCallBacks.equal
		};
		myAnimations = (NSMutableArray*)CFArrayCreateMutable( kCFAllocatorDefault, 0, &arrayCallBacks );
		
		myRefreshInterval = [ATAnimation defaultRefreshInterval];
	}
	
	return self;
}

- (void) dealloc
{
	[myAnimations makeObjectsPerformSelector:@selector(retainControl)];
	[myAnimations release];
	if ( myTimer ) [self stopTimer];
	[super dealloc];
}

#pragma mark -

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

#pragma mark -

- (void) addAnimation: (ATAnimation*) animation
{
	if ( [myAnimations indexOfObjectIdenticalTo:animation] != NSNotFound )
		return;
	
	[myAnimations addObject:animation];
	[self sortAnimations];
	[animation surrenderControlToGroup:self];
	if ( [animation isRunning] ) [self animationStartedRunning]; 
}

- (void) addAnimations: (ATAnimation*) firstAnimation, ...
{
	va_list ap;
	ATAnimation* anim;
	BOOL someAnimationRunning = NO;
	va_start( ap, firstAnimation );
	
	anim = firstAnimation;
	do {
		if ( [myAnimations indexOfObjectIdenticalTo:anim] != NSNotFound )
			continue;
		
		[myAnimations addObject:anim];
		[anim surrenderControlToGroup:self];
		if ( [anim isRunning] ) someAnimationRunning = YES;
	} while ( anim = va_arg(ap, ATAnimation*) );
	
	[self sortAnimations];
	if ( someAnimationRunning ) [self animationStartedRunning]; 
	
	va_end( ap );
}

- (void) removeAnimation: (ATAnimation*) animation
{
	[myAnimations removeObject:animation];
	[animation retainControl];
	[self animationStoppedRunning];
}

- (void) removeAnimations: (ATAnimation*) firstAnimation, ...
{
	va_list ap;
	ATAnimation* anim;
	BOOL someAnimationRunning = NO;
	va_start( ap, firstAnimation );
	
	anim = firstAnimation;
	do {
		int index;
		if ( (index = [myAnimations indexOfObjectIdenticalTo:anim]) != NSNotFound ) {
			if ( [anim isRunning] ) someAnimationRunning = YES;
			[myAnimations removeObjectAtIndex:index];
			[anim retainControl];
		}
	} while ( anim = va_arg(ap, ATAnimation*) );
	
	if ( someAnimationRunning ) [self animationStoppedRunning]; 
	
	va_end( ap );
}

- (NSEnumerator*) animationEnumerator
{
	return [myAnimations objectEnumerator];
}

#pragma mark -

- (void) animationStartedRunning
// Some animation in the group was started. If our timer isn't running, start it.
{
	if ( !myTimer ) [self startTimer];
}

- (void) animationStoppedRunning
// Some animation in the group stopped running. If no other animation is running, stop our timer.
{
	NSEnumerator* enumerator = [myAnimations objectEnumerator];
	ATAnimation* anim;
	BOOL someAnimationRunning = NO;
	if ( !myTimer ) return;
	
	while ( anim = [enumerator nextObject] ) {
		if ( [anim isRunning] ) {
			someAnimationRunning = YES;
			break;
		}
	}
	
	if ( !someAnimationRunning ) [self stopTimer];
}

- (void) delegateDidChangeForAnimation: (ATAnimation*) animation
{
	[self sortAnimations];
}

- (void) refresh: (NSTimer*) timer
// Called periodically by the timer. If one animation runs in blocking mode, it calls this method directly from its loop.
{
	NSEnumerator* animEnumerator;
	ATAnimation* anim;
	NSTimeInterval refreshTime = [NSDate timeIntervalSinceReferenceDate];
	
		// [1] save animation progesses
	animEnumerator = [myAnimations objectEnumerator];
	while ( anim = [animEnumerator nextObject] ) {
		if ( [anim isRunning] ) [anim beginRefreshWithTime:refreshTime];
	}
	
		// [2a] invoke the refresh selector on all running animations
	animEnumerator = [myAnimations objectEnumerator];
	while ( anim = [animEnumerator nextObject] ) {
		if ( [anim isRunning] ) [anim invokeRefreshSelector];
	}
	
		// [2b] draw all running ATViewAnimations in the group
	animEnumerator = [myAnimations objectEnumerator];
	anim = [animEnumerator nextObject];
	do {
		NSView* view = nil;
		BOOL ignoreOpacity;
		
			// Notes:
			// * For views with multiple animations running, we mark each animation rect as needing display
			//   and then send -displayIfNeeded to the view. This assures the drawing routine to be called
			//   only once. Views that wish to limit drawing to the animation rects can do so by querying
			//   -getRectsBeingDrawn:count:; all other views will simply draw the union rect, which gets
			//   passed as the parameter to -drawRect:.
			// * We never ignore opacity if more than one animation is drawing to a view, because even if
			//   the animations' drawing rects are opaque, their union rect may contain areas that are not.
		
			// find the next bunch of (running) view animations with a common target view
		do {
			if ( [anim isRunning] && [anim isKindOfClass:[ATViewAnimation class]] ) {
				if ( !view ) {
					view = [(ATViewAnimation*)anim targetView];
					ignoreOpacity = [(ATViewAnimation*)anim ignoresOpacity];
					[view setNeedsDisplayInRect:[(ATViewAnimation*)anim drawingRect]];
				} else if ( [(ATViewAnimation*)anim targetView] == view ) {
					[view setNeedsDisplayInRect:[(ATViewAnimation*)anim drawingRect]];
					ignoreOpacity = NO;
				} else break;
			}
		} while ( anim = [animEnumerator nextObject] );
		
			// tell the view to draw
		if ( view ) {
			NS_DURING {
				if ( ignoreOpacity ) [view displayIfNeededIgnoringOpacity];
				else [view displayIfNeeded];
			} NS_HANDLER {
				NSLog( @"ATAnimationGroup discarding exception '%@' (reason '%@') that raised while drawing target view 0x%x.", [localException name], [localException reason], view );
			} NS_ENDHANDLER;
		}
	} while ( anim );
	
		// [3] let animations check whether they're finished
	animEnumerator = [myAnimations objectEnumerator];
	while ( anim = [animEnumerator nextObject] ) {
		if ( [anim isRunning] ) [anim finishRefresh];
	}
}

@end

#pragma mark -

@implementation ATAnimationGroup (Private)

static int compareAnimations( id anim1, id anim2, void* p )
{
	id tv1 = [anim1 isKindOfClass:[ATViewAnimation class]] ? [anim1 targetView] : (id)UINTPTR_MAX;
	id tv2 = [anim2 isKindOfClass:[ATViewAnimation class]] ? [anim2 targetView] : (id)UINTPTR_MAX;
	return ( tv1 < tv2 ) ? NSOrderedAscending : ( tv1 > tv2 ) ? NSOrderedDescending : NSOrderedSame;
}

- (void) sortAnimations
{
	[myAnimations sortUsingFunction:compareAnimations context:NULL];
}

- (void) startTimer
{
	NSAssert( !myTimer, @"-[ATAnimationGroup startTimer] found an exising timer." );
	myTimer = [[NSTimer timerWithTimeInterval:myRefreshInterval target:self
		selector:@selector( refresh: ) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSEventTrackingRunLoopMode];
}

- (void) stopTimer
{
	NSAssert( myTimer, @"-[ATAnimationGroup stopTimer] found no timer." );
	[myTimer invalidate];
	[myTimer release];
	myTimer = nil;
}

@end





