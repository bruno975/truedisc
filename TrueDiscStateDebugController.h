//
//  TrueDiscStateDebugController.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrueDiscStateDebugController : NSWindowController
{
    IBOutlet NSMatrix *stepOrContinuousRadioButtons;
    
    IBOutlet NSForm *variablesForm;
    IBOutlet NSForm *historyVariablesForm;
    
    IBOutlet NSButton *logButton;
}

- (void)
setStateVariable: (int) variable
toState:          (int) state;

- (void)
setStateHistoryVariable: (int) variable
toState:                 (int) state;

- (BOOL) step;
- (BOOL) log;

@end
