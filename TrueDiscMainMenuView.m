//
//  TrueDiscMainMenuView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/27/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscMainMenuView.h"


@implementation TrueDiscMainMenuView

- (void) awakeFromNib
{
    NSArray *textFields = [NSArray arrayWithObjects: burnText, restoreText, licenseText, nil];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: [NSColor whiteColor]];
    }
    
    [[self window] resetCursorRects];
}

- (void) selectBurnMenuItem
{
//    NSColor *fadedWhite = [NSColor colorWithDeviceWhite: 1.0 alpha: 0.3];
//    
//    [burnText setTextColor: [NSColor whiteColor]];
//    [restoreText setTextColor: fadedWhite];
//    [licenseText setTextColor: fadedWhite];
}

- (void) selectRestoreMenuItem
{
//    NSColor *fadedWhite = [NSColor colorWithDeviceWhite: 1.0 alpha: 0.3];
//    
//    [burnText setTextColor: fadedWhite];
//    [restoreText setTextColor: [NSColor whiteColor]];
//    [licenseText setTextColor: fadedWhite];
}

- (void) disableBurnMenuItem
{
//    [burnText setEnabled: NO];
}

@end
