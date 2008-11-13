//
//  TrueDisc.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class TrueDiscController;

@interface TrueDisc : NSObject
{
    TrueDiscController *trueDiscController;
    id updateChecker;
    BOOL running1030orLater;
    
    BOOL shouldBeginRestore;
    BOOL applicationDidFinishLaunching;
    
    NSFileHandle *diagonsticLog;
}

- (IBAction) showHelpInBrowser: sender;
- (IBAction) checkForUpdates: sender;
- (IBAction) showBuyPageInBrowser: sender;

- (NSFileHandle *) createDiagnosticLog;
- (NSString *) applicationSupportFolder;

@end
