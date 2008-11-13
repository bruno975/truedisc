//
//  TrueDiscStateDebugController.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscStateDebugController.h"


@implementation TrueDiscStateDebugController

- (void)
setStateVariable: (int) variable
toState:          (int) state
{
    [[variablesForm cellAtIndex: variable] setIntValue: state];
}

- (void)
setStateHistoryVariable: (int) variable
toState:                 (int) state
{
    [[historyVariablesForm cellAtIndex: variable] setIntValue: state];
}

- (BOOL) step
{
    return [[stepOrContinuousRadioButtons selectedCell] tag];
}

- (BOOL) log
{
    return ( [logButton state] == NSOnState ) ? YES : NO; 
}

@end
