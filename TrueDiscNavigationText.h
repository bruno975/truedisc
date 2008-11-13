//
//  TrueDiscNavigationText.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrueDiscNavigationText : NSTextField
{
    BOOL isOpaque;
    int boundsTrackingTag;
    
    NSColor *unhighlightedColor;
}

- (void) highlight: (BOOL) isInside;

- (void) updateBoundsTrackingTag;
- (void) removeTrackingTags;

@end
