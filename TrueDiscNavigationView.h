//
//  TrueDiscNavigationView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class TrueDiscNavigationText;

@interface TrueDiscNavigationView : NSView
{
    IBOutlet TrueDiscNavigationText *aboutText;
    IBOutlet TrueDiscNavigationText *burnText;
    IBOutlet TrueDiscNavigationText *restoreText;
    IBOutlet TrueDiscNavigationText *licenseText;
    IBOutlet TrueDiscNavigationText *helpText;
}

- (void) resetNavigationButtons;

@end
