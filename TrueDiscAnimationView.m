//
//  TrueDiscAnimationView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscAnimationView.h"
#import "ATAnimation.h"

#define MINIMUM_DATA 0.0625
//#define DATA 0.34

@implementation TrueDiscAnimationView

- initWithFrame: (NSRect) frameRect
{
    if ( self = [super initWithFrame: frameRect] )
    {
        float components_s[4] = { 0.0, 0.0, 0.0, 0.4 };
        float components2_s[4] = { 0.33333333333, 0.65098039216, 0.94509803922, 0.6 };
        
        int i;
        for ( i = 0; i < 4; i++ )
        {
            blackColor65[i] = components_s[i];
            trueDiscBlue[i] = components2_s[i];
        }
        
        colorspace = CGColorSpaceCreateDeviceRGB();
        
        detachedSlices = 0;
        
        stopImmediately = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector:    @selector( updateProgress: )
                                              name:        @"TrueDiscProgress"
                                              object:      nil                        ];
    }
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                          name:           @"TrueDiscProgress"
                                          object:         nil               ];

    release( sliceAnimation );
        
    CGColorSpaceRelease( colorspace );

    [super dealloc];
}

- (void) awakeFromNib
{

}

- (void) updateProgress: (NSNotification *) note
{
    progressBar = [[note object] floatValue];
    [self setNeedsDisplay: YES];
}   

- (void) beginEncodingAnimationForDataPercentage: (float) dataPercentage
{
    DATA = ( dataPercentage < MINIMUM_DATA ) ? MINIMUM_DATA : dataPercentage;
    
    release(  sliceAnimation );
    
    sliceAnimation = [[ATViewAnimation alloc] initWithDelegate: self
                                              targetView:       self
                                              duration:         0.1875 * ( 2 - DATA )];
    fireEncodingNotification = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscBeginFileReadingStage"
                                          object:               nil                            ];

    [NSTimer scheduledTimerWithTimeInterval: 1.0 / 60.0
             target:                         self
             selector:                       @selector( updateProgressMeter: )
             userInfo:                       nil
             repeats:                        YES                             ];
}

- (void) drawRect: (NSRect) rect
{
    [self drawSpaceAllocationIfNeededInRect: rect];
    [self drawProgressMeterIfNeededInRect: rect];
}

- (void) updateProgressMeter: (NSTimer *) timer
{
    if ( stopImmediately )
    {
        [timer invalidate];
        stopImmediately = NO;
        return;
    }
    
    if ( progress <+ DATA )
        progress = progress + ( 0.00555555555556 * 1.5 ); // = 1/180
    else
    {
        if ( fireEncodingNotification )
        {
            fireEncodingNotification = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscBeginDataEncodingStage"
                                                  object:               nil                             ];

        }
        progress = progress + ( 0.00555555555556 / 1.5 ); // = 1/180
    }
    
    if ( progress > 1.0 )
    {
        [timer invalidate];
        progress = 1.0; // clamp at end to avoid drawing artifacts

        [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscBeginDataInterleavingStage"
                                              object:               nil                                 ];

        [NSTimer scheduledTimerWithTimeInterval: 0.0
                 target:                         self
                 selector:                       @selector( prepareForDataInterleavingAnimation: )
                 userInfo:                       nil
                 repeats:                        NO                             ];
    }
    
    [self setNeedsDisplay: YES]; // displayRectIgnoringOpacity: [self bounds]];
}

- (void) prepareForDataInterleavingAnimation: (NSTimer *) theTimer
{
    unencodedSliceSize = ( DATA * 2 * PI ) / 16;
    encodedSliceSize = ( ( 1.0 - DATA ) * 2 * PI ) / 16;
    
    [self detachSlice];
}

- (void) haltInProgressAnimation
{
    [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscResetAnimation"
                                          object:               nil                     ];

    stopImmediately = YES;
}

- (void) resetVisuals
{
    detachedSlices = 0;
    progress = 0.0;
    progressBar = 0.0;
    [self setNeedsDisplay: YES];
}

- (void) detachSlice
{
    detachedSlices++;
    [sliceAnimation setProgress: 0.0];
    [sliceAnimation run];
}

- (void) animationDidEnd: (ATAnimation*) animation
{
    if ( detachedSlices < 16 )
        [self detachSlice];
    else
    {
        // we're all done
        [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscEncodingAnimationCompleted"
                                              object:               nil                                 ];

    }
}

- (void) drawSpaceAllocationIfNeededInRect: (NSRect) rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // required
    CGContextSetFillColorSpace( context, colorspace );
    CGContextSetStrokeColorSpace( context, colorspace );
    
    if ( detachedSlices == 0 )
    {
        // we haven't begun our slice animation
        if ( progress > 0.0 && progress <= 1.0 )
        {
            CGContextSaveGState( context );
            
                rect = [self bounds];

                float x = rect.origin.x + ( rect.size.width / 2 );
                float y = rect.origin.y + ( rect.size.height / 2 );
                BOOL clockwise = YES;
                
                CGContextSetLineWidth( context, 196.0 );
                
                float dataPlusEncoding = 2 * PI * progress;
                float data = 2 * PI * DATA;
                float encoding = dataPlusEncoding - data;
                
                CGContextBeginPath( context );
                CGContextSetStrokeColor( context, blackColor65 );
                
                CGContextAddArc( context, x
                                        , y
                                        , 171.0
                                        , ( PI / 2.0 )
                                        , ( PI / 2.0 ) - ( ( dataPlusEncoding > data ) ? data : dataPlusEncoding )
                                        , clockwise ) ;

                CGContextStrokePath( context );
                
                if ( dataPlusEncoding > data )
                {
                    CGContextBeginPath( context );
                    CGContextSetStrokeColor( context, trueDiscBlue );
                    
                    CGContextAddArc( context, x
                                            , y
                                            , 171.0
                                            , ( PI / 2.0 ) - data
                                            , ( PI / 2.0 ) - data - encoding
                                            , clockwise ) ;

                    CGContextStrokePath( context );
                }
                
            CGContextRestoreGState( context );
        }
    }
    else
    {
        // we're doing the detach slices animation or have finished it
        CGContextSaveGState( context );
            
            int i;
            rect = [self bounds];

            float x = rect.origin.x + ( rect.size.width / 2 );
            float y = rect.origin.y + ( rect.size.height / 2 );
            BOOL clockwise = YES;
            
            CGContextSetLineWidth( context, 196.0 );

            //
            // draw the encoded data slices
            //
            
            CGContextSetStrokeColor( context, trueDiscBlue );
            
            if ( detachedSlices < 16 )
            {
                // we need to draw/animate our expandable slice
                CGContextBeginPath( context );
                
                int remainingSlices = 16 - detachedSlices;
                float desiredStart = remainingSlices * unencodedSliceSize; 
                float currentStart = ( PI / 2.0 ) - ( desiredStart + ( unencodedSliceSize * ATEaseFunction( ATEaseFunction( 1.0 - [sliceAnimation progress] ) ) ) );
                
                CGContextAddArc( context, x
                                        , y
                                        , 171.0
                                        , currentStart
                                        , currentStart - ( remainingSlices * encodedSliceSize )
                                        , clockwise ) ;

                CGContextStrokePath( context );
            }
            
//            CGContextSetStrokeColorWithColor( context, blackColor50 );

            for ( i = 0; i < detachedSlices; i++ )
            {
                // now draw each visible encoded fixed-size slices in turn, starting with the last slice
                CGContextBeginPath( context );
                
                float start = ( PI / 2.0 ) - ( ( ( 16 - i ) * unencodedSliceSize ) + ( ( 15 - i ) * encodedSliceSize ) );
                CGContextAddArc( context, x
                                        , y
                                        , 171.0
                                        , start
                                        , start - encodedSliceSize
                                        , clockwise ) ;

                CGContextStrokePath( context );
            }
            
            //
            // now draw the unencoded data slices
            //
            
            CGContextSetStrokeColor( context, blackColor65 );

            if ( detachedSlices < 16 )
            {
                // we need to draw our expandable slice
                CGContextBeginPath( context );
                
                CGContextAddArc( context, x
                                        , y
                                        , 171.0
                                        , ( PI / 2.0 )
                                        , ( PI / 2.0 ) - ( ( 16 - detachedSlices ) * unencodedSliceSize )
                                        , clockwise ) ;

                CGContextStrokePath( context );
            }
            
            for ( i = 0; i < detachedSlices; i++ )
            {
                // we need to draw/animate our unencoded fixed-size slices in turn, starting with the last slice
                CGContextBeginPath( context );
                
                float initialStart = ( 15 - i ) * unencodedSliceSize;
                float distance = ( ( 15 - i ) * ( unencodedSliceSize + encodedSliceSize ) ) - initialStart;
                float currentStart;
                
                if ( i == ( detachedSlices - 1 ) )
                    currentStart = ( PI / 2.0 ) - ( initialStart + ( distance * ATEaseFunction( ATEaseFunction( [sliceAnimation progress] ) ) ) );
                else
                    currentStart = ( PI / 2.0 ) - initialStart - distance;

                CGContextAddArc( context, x
                                        , y
                                        , 171.0
                                        , currentStart
                                        , currentStart - unencodedSliceSize
                                        , clockwise ) ;

                CGContextStrokePath( context );
            }
            
        CGContextRestoreGState( context );
    }
}

//- (void) drawSpaceAllocationIfNeededInRect: (NSRect) rect
//{
//    if ( progress > 0.0 && progress < 100.0 )
//    {
//        CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//        
//        CGContextSaveGState( context );
//        
//            rect = [self bounds];
//
//            float x = rect.origin.x + ( rect.size.width / 2 );
//            float y = rect.origin.y + ( rect.size.height / 2 );
//            BOOL clockwise = YES;
//            
//            CGContextSetLineWidth( context, 196.0 );
//            
//            CGContextSetStrokeColorWithColor( context, trueDiscBlue50 );
//            
//            float dataPlusEncoding = ( 2 * PI ) / 16.0;
//            float dataSize = 0.29;
//            float data = dataPlusEncoding * dataSize;
//            float encoding = ( dataPlusEncoding - data )  * progress;
//            
//            int i;
//            for ( i = 0; i < 16; i ++ )
//            {
//                CGContextBeginPath( context );
//                
//                float startAngle = ( PI / 2.0 ) - ( i * ( data + encoding ) ) - data;
//                float endAngle = startAngle - encoding;
//
//                // draw transparent, full donut
//                CGContextAddArc( context, x
//                                        , y
//                                        , 171.0
//                                        , startAngle
//                                        , endAngle
//                                        , clockwise ) ;
//
//                CGContextStrokePath( context );
//            }
//
//        CGContextRestoreGState( context );
//    }
//}

- (void) drawProgressMeterIfNeededInRect: (NSRect) rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // required
    CGContextSetFillColorSpace( context, colorspace );
    CGContextSetStrokeColorSpace( context, colorspace );
    
    CGContextSaveGState( context );
    
        rect = [self bounds];

        float x = rect.origin.x + ( rect.size.width / 2 );
        float y = rect.origin.y + ( rect.size.height / 2 );
        float startAngle = PI / 2.0;
        float endAngle = startAngle - ( 2.0 * PI * progressBar );
        BOOL clockwise = YES;
        
        // draw transparent, full donut
        CGContextAddArc( context, x
                                , y
                                , 171.0
                                , startAngle
                                , endAngle
                                , clockwise ) ;
                       
        CGContextSetLineWidth( context, 196.0 );
        
        CGContextSetStrokeColor( context, blackColor65 );
        
        CGContextStrokePath( context );
    
    CGContextRestoreGState( context );
}

@end
