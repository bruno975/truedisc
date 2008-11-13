//
//  TrueDiscMainMenuView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/27/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class TrueDiscNavigationText;

@interface TrueDiscMainMenuView : NSView
{
    IBOutlet TrueDiscNavigationText *burnText;
    IBOutlet TrueDiscNavigationText *restoreText;
    IBOutlet TrueDiscNavigationText *licenseText;
}

- (void) selectBurnMenuItem;
- (void) selectRestoreMenuItem;
- (void) disableBurnMenuItem;

@end
