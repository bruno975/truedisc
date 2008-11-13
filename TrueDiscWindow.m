//
//  TrueDiscWindow.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/24/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscWindow.h"


@implementation TrueDiscWindow

- (id)
initWithContentRect: (NSRect)             contentRect
styleMask:           (unsigned int)       style
backing:             (NSBackingStoreType) bufferingType
defer:               (BOOL)               flag
{
    self = [super initWithContentRect: contentRect
                  styleMask:           NSBorderlessWindowMask
                  backing:             bufferingType
                  defer:               flag                  ];
    if ( self )
    {
        [self setOpaque: NO];
        [self setBackgroundColor: [NSColor clearColor]];
        [self setMovableByWindowBackground: YES];
    }
    return self;
}

- (BOOL) canBecomeKeyWindow { return YES; }
- (BOOL) canBecomeMainWindow { return YES; }

@end
