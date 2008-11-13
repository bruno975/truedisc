//
//  TrueDiscNavigationView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscNavigationView.h"


@implementation TrueDiscNavigationView

- (void) awakeFromNib
{
    NSArray *textFields = [NSArray arrayWithObjects: aboutText, burnText, restoreText, licenseText, helpText, nil];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: [NSColor whiteColor]];
    }
    
    [[self window] resetCursorRects];
}

- (void) resetNavigationButtons
{
    NSArray *textFields = [NSArray arrayWithObjects: aboutText, burnText, restoreText, licenseText, helpText, nil];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: [NSColor whiteColor]];
    }
}

@end
