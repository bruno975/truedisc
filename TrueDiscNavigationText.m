//
//  TrueDiscNavigationText.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscNavigationText.h"


@implementation TrueDiscNavigationText

- initWithCoder: (NSCoder *) decoder
{
    if ( self = [super initWithCoder: decoder] )
    {
        isOpaque = YES;
        [self setBackgroundColor: [NSColor clearColor]];
    }
    return self;
}

- (void) dealloc
{
    release( unhighlightedColor );
    
    [super dealloc];
}

- (BOOL) acceptsFirstResponder { return YES; }

- (BOOL) isOpaque { return isOpaque; }

- (void) mouseEntered: (NSEvent *) theEvent
{
    isOpaque = NO;
    
    [self highlight: YES];
}

- (void) mouseExited: (NSEvent *) theEvent
{
    [self highlight: NO];
}

- (void) mouseDown: (NSEvent *) event
{
    isOpaque = NO;
    
    [[self superview] setNeedsDisplay: YES];
    
    [self setTextColor: [NSColor trueDiscBlue]];
    
    [self setNeedsDisplayInRect: [self visibleRect]];
}

- (void) highlight: (BOOL) isInside
{
    if ( !unhighlightedColor )
        unhighlightedColor = [[self textColor] retain];
    
    if ( isInside ) [self setTextColor: [NSColor trueDiscBlue]];
    else [self setTextColor: unhighlightedColor];

    [self setNeedsDisplayInRect: [self visibleRect]];
}

- (void) mouseDragged: (NSEvent *) event
{
    isOpaque = NO; // hack to get movable window background working properly

    NSPoint mouseLocation = [self convertPoint: [event locationInWindow]
                                  fromView:     nil                    ];
 
    [self highlight: NSPointInRect( mouseLocation, [self bounds] )];
}

- (void) mouseUp: (NSEvent *) event
{
    isOpaque = NO; // hack to get movable window background working properly

    NSPoint mouseLocation = [self convertPoint: [event locationInWindow]
                                  fromView:     nil                    ];
 
    if ( NSPointInRect( mouseLocation, [self bounds] ) )
    {
        // mouse up inside, send action
        [self sendAction: [self action]
              to:         [self target]];

        [self highlight: NO];
    }

    [self setNeedsDisplayInRect: [self visibleRect]];
}

- (void) viewDidMoveToWindow
{
    isOpaque = YES;  // hack to get movable window background working properly
    
    [[self window] invalidateCursorRectsForView: self];
}

- (void) resetCursorRects
{
    [self addCursorRect: [self visibleRect]
          cursor:        [NSCursor myPointingHandCursor]];
          
    [self updateBoundsTrackingTag];
}

- (void) updateBoundsTrackingTag
{
    [self removeTrackingRect: boundsTrackingTag];
    
    NSPoint loc = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView: nil];
    
    BOOL inside = ( [self hitTest: loc] == self );
    
    if ( inside )
        [[self window] makeFirstResponder: self]; // if the view accepts first responder status
        
    boundsTrackingTag = [self addTrackingRect: [self visibleRect]   
                              owner:           self
                              userData:        nil
                              assumeInside:    inside           ];
}

- (void) removeTrackingTags
{
    [self removeTrackingRect: boundsTrackingTag];
}

- (void) viewWillMoveToWindow: (NSWindow *) win
{
    if ( !win && [self window] )
        [self removeTrackingTags];
        
    [super viewWillMoveToWindow: win];
}

@end
