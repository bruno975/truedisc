//
//  TrueDiscBackgroundView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscBackgroundView.h"


@implementation TrueDiscBackgroundView

- initWithFrame: (NSRect) frameRect
{
    if ( self = [super initWithFrame: frameRect] )
    {
        float components[4] = { 0.0, 0.0, 0.0, 0.5 };
        
        colorspace = CGColorSpaceCreateDeviceRGB();
        color = CGColorCreate( colorspace, components );
    }
    return self;
}

- (void) dealloc
{
    CGColorRelease( color );
    CGColorSpaceRelease( colorspace );
    
    [super dealloc];
}

- (void) drawRect: (NSRect) rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    NSRect bounds = [self bounds];
    
    float x = bounds.origin.x + ( bounds.size.width / 2 );
    float y = bounds.origin.y + ( bounds.size.height / 2 );
    float startAngle = 0.0;
    float endAngle = 2.0 * PI;
    BOOL clockwise = YES;
    
    // draw black, 50% transparent, full donut
    CGContextSetLineWidth( context, 238.0 );
    CGContextSetStrokeColorWithColor( context, color );
    
    CGContextAddArc( context, x
                            , y
                            , 149.0
                            , startAngle
                            , endAngle
                            , clockwise );
                   
    CGContextStrokePath( context );
}

@end
