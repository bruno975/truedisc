//
//  TrueDiscUserInterfaceView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscUserInterfaceView.h"
#import "TrueDiscNavigationView.h"
#import "TrueDiscMainMenuView.h"
#import "TrueDiscBurnMenuView.h"
#import "TrueDiscBurnAnimationView.h"

#ifdef LICENSE_CONTROL
#import <LicenseControl/DetermineOpMode.h>
#endif

@implementation TrueDiscUserInterfaceView

- initWithFrame: (NSRect) frameRect
{
    if ( self = [super initWithFrame: frameRect] )
    {
        float components_s[4] = { 0.0, 0.0, 0.0, 0.7 };
        float components2_s[4] = { 1.0, 1.0, 1.0, 1.0 };
        float components3_S[4] = { 1.0, 1.0, 1.0, 0.8 };
        float components4_s[4] = { 0.0, 0.0, 0.0, 0.5 };

        int i;
        for ( i = 0; i < 4; i++ )
        {
            blackColor70[i] = components_s[i];
            whiteColor100[i] = components2_s[i];
            whiteColor80[i] = components3_S[i];
            blackColor50[i] = components4_s[i];
        }
        
        colorspace = CGColorSpaceCreateDeviceRGB();
        
        NSRect adBannerRect = frameRect;
        adBannerRect.origin.y = 407.0;
        adBannerRect.size.height = 22.0;
        NSTextView *adBanner = [[NSTextView alloc] initWithFrame: adBannerRect];
        [adBanner setDrawsBackground: NO];
        [adBanner setEditable: NO];
        [adBanner setSelectable: NO];
        
        NSString *s = [NSString stringWithFormat: @"Burn CDs and DVDs with damage-resistant %Cmaster copies%C of your files.", 0x201C, 0x201D ];
        NSDictionary *d = [NSDictionary dictionaryWithObject: [NSFont systemFontOfSize: 12.0]
                                        forKey:               NSFontAttributeName           ];
                                        
        NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString: s
                                                                            attributes:     d];
        [mas setAlignment: NSCenterTextAlignment
             range:        NSMakeRange( 0, [s length] )];
        
        [[adBanner textStorage] setAttributedString: mas];
        
        [self addSubview: adBanner];
        [adBanner release];

#ifdef LICENSE_CONTROL
    if ( OpModeLicensed != licensingLevelCheck().opMode )
    {
        // show "Unlicensed" text
        NSRect unlicensedRect = frameRect;
        unlicensedRect.origin.y = 380.0;
        unlicensedRect.size.height = 22.0;
        NSTextView *unlicensedText = [[NSTextView alloc] initWithFrame: unlicensedRect];
        [unlicensedText setDrawsBackground: NO];
        [unlicensedText setEditable: NO];
        [unlicensedText setSelectable: NO];
        
        NSString *text = @"TrueDisc is Unlicensed.\n";
        NSString *text2 = @"(Restores all files. Only burns files < 5 MB in size to CD-R.)";
        NSDictionary *d = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: [NSFont boldSystemFontOfSize: [NSFont systemFontSize]], [NSColor redColor], nil]
                                        forKeys:               [NSArray arrayWithObjects: NSFontAttributeName,  NSForegroundColorAttributeName, nil]];
                                        
        NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString: text
                                                                            attributes:     d   ];

        NSDictionary *d2 = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects: [NSFont systemFontOfSize: 12.0], [NSColor whiteColor], nil]
                                        forKeys:                [NSArray arrayWithObjects: NSFontAttributeName,  NSForegroundColorAttributeName, nil]];
                                        
        NSMutableAttributedString *mas2 = [[NSMutableAttributedString alloc] initWithString: text2
                                                                             attributes:     d2   ];
        [mas appendAttributedString: mas2];
        
        [mas setAlignment: NSCenterTextAlignment
             range:        NSMakeRange( 0, [mas length] )];
        
        [[unlicensedText textStorage] setAttributedString: mas];
        
        [self addSubview: unlicensedText];
        [unlicensedText release];
    }
#endif

    }
    return self;
}

- (void) dealloc
{
    CGColorSpaceRelease( colorspace );

    [super dealloc];
}

- (void) awakeFromNib
{
    NSRect rect = [self frame];
    NSRect navRect = [navView frame];
    navRect.origin.x = rect.origin.x + (( rect.size.width - navRect.size.width ) / 2.0 );
    navRect.origin.y = 447.0;
    
    [navView setFrame: navRect];
    [self addSubview: navView];
    
//    NSRect mainMenuRect = [mainMenuView frame];
//    mainMenuRect.origin.x = rect.origin.x + (( rect.size.width - mainMenuRect.size.width ) / 2.0 );
//    mainMenuRect.origin.y = 50.0;
//
//    [mainMenuView setFrame: mainMenuRect];
//    [mainMenuView setHidden: YES];
//    [self addSubview: mainMenuView];
//    
//    NSRect burnMenuRect = [burnMenuView frame];
//    burnMenuRect.origin.x = rect.origin.x + (( rect.size.width - burnMenuRect.size.width ) / 2.0 );
//    burnMenuRect.origin.y = 50.0;
//
//    [burnMenuView setFrame: burnMenuRect];
//    [burnMenuView setHidden: YES];
//    [self addSubview: burnMenuView];
//
//    NSRect burnAnimationRect = [burnAnimationView frame];
//    burnAnimationRect.origin.x = rect.origin.x + (( rect.size.width - burnAnimationRect.size.width ) / 2.0 );
//    burnAnimationRect.origin.y = 50.0;
//
//    [burnAnimationView setFrame: burnAnimationRect];
//    [burnAnimationView setHidden: YES];
//    [self addSubview: burnAnimationView];
//    
//    NSRect readyToBurnRect = [readyToBurnTextView frame];
//    readyToBurnRect.origin.x = rect.origin.x + (( rect.size.width - readyToBurnRect.size.width ) / 2.0 );
//    readyToBurnRect.origin.y = 105.0;
//
//    [readyToBurnTextView setFrame: readyToBurnRect];
//    [readyToBurnTextView setHidden: YES];
//    [self addSubview: readyToBurnTextView];
//
//    NSRect burningRect = [burningTextView frame];
//    burningRect.origin.x = rect.origin.x + (( rect.size.width - burningRect.size.width ) / 2.0 );
//    burningRect.origin.y = 105.0;
//
//    [burningTextView setFrame: burningRect];
//    [burningTextView setHidden: YES];
//    [self addSubview: burningTextView];
    
    NSRect tabRect = [tabView frame];
    tabRect.origin.x = rect.origin.x + (( rect.size.width - tabRect.size.width ) / 2.0 );
    tabRect.origin.y = 35.0;

    [tabView setFrame: tabRect];
    [self addSubview: tabView];
    
    [[self window] makeKeyAndOrderFront: nil];
    
    [[self window] enableCursorRects];
}

- (void) drawRect: (NSRect) rect
{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    // required
    CGContextSetFillColorSpace( context, colorspace );
    CGContextSetStrokeColorSpace( context, colorspace );
    
    NSRect bounds = [self bounds];
    float x = bounds.origin.x + ( bounds.size.width / 2 );
    float y = bounds.origin.y + ( bounds.size.height / 2 );
    float startAngle = 0.0;
    float endAngle = 2.0 * PI;
    BOOL clockwise = YES;
    
    // draw black, 50% transparent, full donut
    CGContextSetLineWidth( context, 238.0 );
    
    CGContextSetFillColor( context, blackColor70 );
    CGContextSetStrokeColor( context, blackColor70 );

    CGContextAddArc( context, x
                            , y
                            , 149.0
                            , startAngle
                            , endAngle
                            , clockwise );
                   
    CGContextStrokePath( context );

    // draw title bar partial donut
    CGContextBeginPath( context );
    
    CGContextSetFillColor( context, blackColor50 );
    CGContextSetStrokeColor( context, blackColor50 );

    CGContextAddArc( context, x
                            , y
                            , 269.0
                            , 0.788 * PI
                            , 0.212 * PI
                            , clockwise );
                   
    CGContextSetLineWidth( context, 1.0 );
    
    CGContextClosePath( context );
    CGContextFillPath( context );
    
    // draw ad banner
    CGContextBeginPath( context );
    
    CGContextSetStrokeColor( context, whiteColor100 );
    CGContextSetFillColor( context, whiteColor80 );

    CGContextSetLineWidth( context, 2.0 );

    CGContextAddArc( context, x
                            , y
                            , 269.0
                            , 0.833 * PI
                            , 0.788 * PI
                            , clockwise );
    
    CGContextAddArc( context, x
                            , y
                            , 269.0
                            , 0.212 * PI
                            , 0.167 * PI
                            , clockwise );


    CGContextClosePath( context );
    CGContextDrawPath( context, kCGPathFillStroke );

    // draw the innermost white circle
    CGContextBeginPath( context );
    
    CGContextAddArc( context, x
                            , y
                            , 29.0
                            , startAngle
                            , endAngle
                            , clockwise );
                   
    CGContextSetLineWidth( context, 2.0 );
    
    CGContextStrokePath( context );
    
    // draw the two outermost white circles
    CGContextSetLineWidth( context, 3.5 );
    
    CGContextBeginPath( context );
    
    CGContextAddArc( context, x
                            , y
                            , 73.0
                            , startAngle
                            , endAngle
                            , clockwise );
                   
    CGContextStrokePath( context );
    
    CGContextBeginPath( context );
    
    CGContextAddArc( context, x
                            , y
                            , 269.0
                            , startAngle
                            , endAngle
                            , clockwise );
                   
    CGContextStrokePath( context );
}

- (void) resetAll;
{
    [self resetNavigationButtons];
    [self showMainMenu];
    [self hideBurning];
    [self hideBurnMenu];
    [self hideReadyToBurn];
}

- (void) resetNavigationButtons
{
    [navView resetNavigationButtons];
}

- (void) showMainMenu
{
    [tabView selectTabViewItemAtIndex: 0];
//    [mainMenuView setHidden: NO];
}

- (void) hideMainMenu
{
    [tabView selectTabViewItemAtIndex: 5];
//    [mainMenuView setHidden: YES];
}

- (void) showBurnMenu
{
    [tabView selectTabViewItemAtIndex: 1];
//    [burnMenuView setHidden: NO];
}

- (void) hideBurnMenu
{
    [tabView selectTabViewItemAtIndex: 5];
//    [burnMenuView setHidden: YES];
}

- (void) showAnimationBurn
{
    [tabView selectTabViewItemAtIndex: 2];
//    [burnAnimationView setHidden: NO];
}

- (void) hideAnimationBurn
{
    [tabView selectTabViewItemAtIndex: 5];
//    [burnAnimationView setHidden: YES];
}

- (void) showReadyToBurn;
{
    [tabView selectTabViewItemAtIndex: 3];
//    [readyToBurnTextView setHidden: NO];
}

- (void) hideReadyToBurn;
{
    [tabView selectTabViewItemAtIndex: 5];
//    [readyToBurnTextView setHidden: YES];
}

- (void) showBurning;
{
    [tabView selectTabViewItemAtIndex: 5];
//    [burningTextView setHidden: NO];
}

- (void) hideBurning;
{
    [tabView selectTabViewItemAtIndex: 5];
//    [burningTextView setHidden: YES];
}

- (void) hideDVDBurnOption
{
    [burnMenuView hideDVDBurnOption];
}

- (void) hideDVDPlusRDoubleLayerBurnOption
{
    [burnMenuView hideDVDPlusRDoubleLayerBurnOption];
}

- (void) selectBurnMenuItem
{
    [mainMenuView selectBurnMenuItem];
}

- (void) selectRestoreMenuItem
{
    [mainMenuView selectRestoreMenuItem];
}

- (void) disableBurnMenuItem
{
    [mainMenuView disableBurnMenuItem];
}

@end