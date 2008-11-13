//
//  TrueDiscBurnMenuView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/28/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class TrueDiscNavigationText;

@interface TrueDiscBurnMenuView : NSView
{
    IBOutlet TrueDiscNavigationText *cdrText;
    IBOutlet TrueDiscNavigationText *dvdrText;
    IBOutlet TrueDiscNavigationText *dvdplusrdoublelayerText;
}

- (void) hideDVDBurnOption;
- (void) hideDVDPlusRDoubleLayerBurnOption;

@end
