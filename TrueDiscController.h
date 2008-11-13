//
//  TrueDiscController.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

// #define DEBUG_STATECHART

@class TrueDiscUserInterfaceView, TrueDiscAnimationView;
@class TrueDiscWindow, TrueDiscAnimationWindow;

@class TrueDiscNavigationView;

#ifdef DEBUG_STATECHART
@class TrueDiscStateDebugController;
#endif

@class DSBurnInfo;

enum TrueDiscBurnType {
    CDR = 0,
    DVDRorDVDPlusR = 1,
    DVDPlusRDoubleLayer = 2
};

@interface TrueDiscController : NSWindowController
{
    // the UI objects we're managing with this controller
    IBOutlet TrueDiscUserInterfaceView * uiView;
    IBOutlet TrueDiscAnimationView     * animationView;
    
    IBOutlet TrueDiscWindow           * uiWindow;
    IBOutlet TrueDiscAnimationWindow  * animationWindow;

    IBOutlet TrueDiscNavigationView *navigationView;
    
    DSBurnInfo   * burnInfo;
    NSDictionary * plist;
    
    BOOL canBurnToCDR;
    BOOL canBurnToDVDR;
    BOOL canBurnToDVDPlusR;
    BOOL canBurnToDVDPlusRDoubleLayer;
    
    BOOL isAnimating;
    BOOL isBurning;
    
    int burnType; 
    float discCapacity;

#ifdef DEBUG_STATECHART    
    TrueDiscStateDebugController *debugController;
#endif    
    
    // private state support code
    int16_t state_variables[26];
    int16_t history_state_variables[26];
}

- (IBAction) about:    sender;
- (IBAction) burn:     sender;
- (IBAction) restore:  sender;
- (IBAction) license:  sender;
- (IBAction) purchase: sender;
- (IBAction) help:     sender;

- (IBAction) chooseBurnDiscFormat: sender;
- (IBAction) chooseBurnFile:       sender;
- (IBAction) beginBurnSession:     sender;

- (void) registerForDeviceNotifications;
- (BOOL) discIsMounted;
- (BOOL) trueDiscIsMounted;
- (NSData *) generateTrueDiscXMLData;

- (uint64_t) sizeForFilepath: (NSString *) filepath;
- (NSString *) restoreFilename;

- (NSString *) appPath;
- (NSString *) readMePath;

- (void)
gotoState: (int) to_state
variable:  (int) variable
event:     (SEL) eventSelector;

@end

#define state( state_var ) state_variables[ ( *#state_var - 'a' ) ]
#define ui_for_state( state_num ) - (void) state_## state_num
#define ui_for_transient( state_num ) - (void) state_## state_num
#define go( state_var, to_state ) [self gotoState: to_state variable: ( *#state_var - 'a' ) event: _cmd ];
#define go_transient( state_var, to_state ) [self gotoState: to_state variable: ( *#state_var - 'a' ) event: _cmd ];

#define go_history( state_var, default_state ) \
if ( history_state_variables[ ( *#state_var - 'a' ) ] == -1 ) go( state_var, default_state ) \
else go( state_var, history_state_variables[ ( *#state_var - 'a' ) ] )

// go( state_var, ( history_state_variables[ ( *#state_var - 'a' ) ] == -1 ) ? default_state : history_state_variables[ ( *#state_var - 'a' ) ] )