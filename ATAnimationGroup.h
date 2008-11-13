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

@interface ATAnimationGroup : NSObject
{
	NSMutableArray*	myAnimations;
							// array is sorted: view animations go first, sorted by target view in
							// ascending order; then the other animations follow in undefined order
	NSTimeInterval	myRefreshInterval;
	NSTimer*		myTimer;
}

- (NSTimeInterval) refreshInterval;
- (void) setRefreshInterval: (NSTimeInterval) secs;

- (void) addAnimation: (ATAnimation*) animation;
- (void) addAnimations: (ATAnimation*) firstAnimation, ...;
- (void) removeAnimation: (ATAnimation*) animation;
- (void) removeAnimations: (ATAnimation*) firstAnimation, ...;
	// Note that animations are not retained by the group.

- (NSEnumerator*) animationEnumerator;
@end

	/* The following methods should only invoked by ATAnimations,
	   or by the animation group itself. */
@interface ATAnimationGroup (Animations)
- (void) animationStartedRunning;
- (void) animationStoppedRunning;
- (void) delegateDidChangeForAnimation: (ATAnimation*) animation;
- (void) refresh: (NSTimer*) timer;
@end

