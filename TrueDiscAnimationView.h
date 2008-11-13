//
//  TrueDiscAnimationView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscView.h"

@class ATAnimation;

@interface TrueDiscAnimationView : TrueDiscView
{
    float progressBar;
    float progress;
    float DATA;

    float blackColor65[4];
    float trueDiscBlue[4];
    CGColorSpaceRef colorspace;

    int detachedSlices;
    float unencodedSliceSize;
    float encodedSliceSize;
    ATAnimation *sliceAnimation;
    
    BOOL fireEncodingNotification;
    BOOL stopImmediately;
}

- (void) resetVisuals;
- (void) haltInProgressAnimation;

- (void) beginEncodingAnimationForDataPercentage: (float) dataPercentage;

- (void) drawSpaceAllocationIfNeededInRect: (NSRect) rect;
- (void) drawProgressMeterIfNeededInRect: (NSRect) rect;

- (void) detachSlice;

@end
