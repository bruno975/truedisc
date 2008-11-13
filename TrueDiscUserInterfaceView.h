//
//  TrueDiscUserInterfaceView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/26/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscView.h"

@class TrueDiscMainMenuView, TrueDiscBurnMenuView, TrueDiscBurnAnimationView;

@interface TrueDiscUserInterfaceView : TrueDiscView
{
    IBOutlet TrueDiscNavigationView    * navView;
    IBOutlet TrueDiscMainMenuView      * mainMenuView;
    IBOutlet TrueDiscBurnMenuView      * burnMenuView;
    IBOutlet TrueDiscBurnAnimationView * burnAnimationView;
    IBOutlet NSTextView                * bannerTextView;
    IBOutlet NSTextField               * readyToBurnTextView;
    IBOutlet NSTextField               * burningTextView;
    
    IBOutlet NSTabView * tabView;

    float blackColor70[4];
    float blackColor50[4];
    float whiteColor100[4];
    float whiteColor80[4];
    CGColorSpaceRef colorspace;
}

- (void) resetAll;
- (void) resetNavigationButtons;
- (void) showMainMenu;
- (void) hideMainMenu;
- (void) showBurnMenu;
- (void) hideBurnMenu;
- (void) showAnimationBurn;
- (void) hideAnimationBurn;
- (void) showReadyToBurn;
- (void) hideReadyToBurn;
- (void) showBurning;
- (void) hideBurning;

- (void) hideDVDBurnOption;
- (void) hideDVDPlusRDoubleLayerBurnOption;

- (void) selectBurnMenuItem;
- (void) selectRestoreMenuItem;
- (void) disableBurnMenuItem;

@end
