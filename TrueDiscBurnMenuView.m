//
//  TrueDiscBurnMenuView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/28/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscBurnMenuView.h"


@implementation TrueDiscBurnMenuView

- (void) awakeFromNib
{
    NSArray *textFields = [NSArray arrayWithObjects: cdrText, dvdrText, dvdplusrdoublelayerText, nil];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: [NSColor whiteColor]];
    }
    
    [[self window] resetCursorRects];
}

- (void) hideDVDBurnOption
{
    if ( dvdrText )
    {
        [dvdrText removeFromSuperview];
        dvdrText = nil;
    }
}

- (void) hideDVDPlusRDoubleLayerBurnOption
{
    if ( dvdplusrdoublelayerText )
    {
        [dvdplusrdoublelayerText removeFromSuperview];
        dvdplusrdoublelayerText = nil;
    }
}

@end
