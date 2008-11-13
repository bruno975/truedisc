//
//  TrueDiscBackgroundWindow.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscBackgroundWindow.h"


@implementation TrueDiscBackgroundWindow

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
        [self setMovableByWindowBackground: YES];
    }
    return self;
}

@end
