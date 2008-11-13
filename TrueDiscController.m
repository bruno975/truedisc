//
//  TrueDiscController.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDisc.h"
#import "TrueDiscController.h"
#import "TrueDiscUserInterfaceView.h"
#import "TrueDiscAnimationView.h"
#import "TrueDiscWindow.h"
#import "TrueDiscAnimationWindow.h"

#import "DSBurnInfo.h"
#import "DSBurnDataProvider.h"
#import "DSTrueDiscDecoder.h"

#import <DiscRecordingUI/DiscRecordingUI.h>
#import <DiscRecording/DRDevice.h>

#import "fec.h"

#ifdef DEBUG_STATECHART
#import "TrueDiscStateDebugController.h"
#endif

#ifdef LICENSE_CONTROL
#warning LicenseControl enabled
#import <LicenseControl/LicensingLauncherC.h>
#import <LicenseControl/DetermineOpMode.h>
#endif

// set STATE_COUNT to the highest ui_for_state( ### ) defined below
#define STATE_COUNT 151
static SEL state_methods[STATE_COUNT];

@interface NSObject ( For10_2 )
- (uint64_t) estimateLength;
@end

@implementation TrueDiscController

+ (void) initialize
{
    // setup state methods selectors (these are valid for class and instance objects)
    int i;
    for ( i = 0; i < STATE_COUNT; i++ )
    {
        // Note: this will register the selector regardless of wether or not the class actually implements it
        state_methods[i] = NSSelectorFromString( [NSString stringWithFormat: @"state_%00d", i] );
    }
}

- initWithWindow: (NSWindow *) window
{
    if ( self = [super initWithWindow: window] )
    {
        int i;
        for ( i = 0; i < 26; i++ )
        {
            state_variables[i] = -1; // this insures that history_state_variables is set properly after the first state is set
            history_state_variables[i] = -1; // this means that no history state has been set
        }
        
        canBurnToCDR = NO;
        canBurnToDVDR = NO;
        canBurnToDVDPlusR = NO;
        canBurnToDVDPlusRDoubleLayer = NO;
        
        isAnimating = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                              selector:    @selector( encodingAnimationCompleted: )
                                              name:        @"TrueDiscEncodingAnimationCompleted"
                                              object:      nil                                    ];

#ifdef DEBUG_STATECHART    
        debugController = [[TrueDiscStateDebugController alloc] initWithWindowNibName: @"Debug"];
#endif        
    }
    return self;
}

- (void) dealloc
{
    release( plist );
    
#ifdef DEBUG_STATECHART    
    release( debugController );
#endif        

    [[DRNotificationCenter currentRunLoopCenter] removeObserver: self
                                                 name:           DRDeviceAppearedNotification
                                                 object:         nil                         ];

    [[DRNotificationCenter currentRunLoopCenter] removeObserver: self
                                                 name:           DRDeviceDisappearedNotification
                                                 object:         nil                            ];

    [[NSNotificationCenter defaultCenter] removeObserver: self
                                          name:           @"TrueDiscEncodingAnimationCompleted"
                                          object:         nil                                 ];

    [super dealloc];
}

#pragma mark -
#pragma mark Action/Events

- (void) awakeFromNib
{
#ifdef DEBUG_STATECHART    
    [debugController showWindow: nil];
#endif
    
    NSPoint winOrigin = [[self window] frame].origin;

    [animationWindow setFrameOrigin: winOrigin];
    
    [[self window] addChildWindow: animationWindow
                   ordered:        NSWindowBelow  ];
    
    // enter our start states
    go( a, 1 );
    
    // register for device events (do not move this above go( a, 1 ) above, as it issues events during registration)
    [self registerForDeviceNotifications];
}

- (BOOL)
panel:              (id)         sender
shouldShowFilename: (NSString *) filename
{
    // *filename can be nil, which causes isFilePackageAtPath: to crash in CoreFoundation
    if ( filename && [[NSWorkspace sharedWorkspace] isFilePackageAtPath: filename] ) return NO;
    
    float maxSize = ((discCapacity * 15) / 16);
    uint64_t fileSize = [self sizeForFilepath: filename];

#ifdef LICENSE_CONTROL
    if ( OpModeLicensed != licensingLevelCheck().opMode )
        return ( fileSize < MAXIMUM_UNLICENSED_FILE_SIZE ) ? YES : NO;
    else
#endif
        return ( fileSize < maxSize ) ? YES : NO;

    return YES;
}

- (uint64_t) sizeForFilepath: (NSString *) filepath;
{
    Boolean isDirectory = false;
    FSRef ref;
    OSStatus err;
    
    err = FSPathMakeRef( (const UInt8 *)[filepath UTF8String], &ref, &isDirectory ); 

    if ( err == noErr )
    {
        OSErr osErr;
        FSCatalogInfo catalogInfo;
        
        osErr = FSGetCatalogInfo( &ref, kFSCatInfoDataSizes, &catalogInfo, NULL, NULL, NULL );
        
        if ( osErr == noErr )
        {
            return catalogInfo.dataLogicalSize;
        }
        else
        {
            NSLog( @"TrueDisc: failed to get size of selected file. Reason: %d", osErr );
            return 0;
        }
    }
    return 0; // indicates failure
}

- (IBAction) about: sender
{
    [NSApp orderFrontStandardAboutPanel: nil];
}

- (IBAction) burn: sender
{
    if ( isBurning )
    {
        [uiView resetNavigationButtons];
        return;
    }
    
    if ( !( canBurnToCDR || canBurnToDVDR || canBurnToDVDPlusR || canBurnToDVDPlusRDoubleLayer ) )
    {
        NSRunCriticalAlertPanel( @"This computer doesn't have a supported optical burner."
                               , @"This computer doesn't appear to be able to burn to CD-R, DVD-R, DVD+R, or DVD+R Double Layer. If you believe you have gotten this message in error, please contact TrueDisc technical support."
                               , @"OK"
                               , nil
                               , nil
                               ) ;
    }
    
    [uiView hideMainMenu];
    [uiView hideBurnMenu];
    [uiView hideBurning];
    [uiView hideReadyToBurn];
    [uiView hideAnimationBurn];
    if ( isAnimating )
    {
        isAnimating = NO;
        [animationView haltInProgressAnimation];
    }
    [animationView resetVisuals];
    
    if ( !( canBurnToDVDR || canBurnToDVDPlusR ) )
        [uiView hideDVDBurnOption];
        
    if ( !canBurnToDVDPlusRDoubleLayer )
        [uiView hideDVDPlusRDoubleLayerBurnOption];

#ifdef LICENSE_CONTROL
    if ( OpModeLicensed != licensingLevelCheck().opMode )
    {
        [uiView hideDVDBurnOption];
        [uiView hideDVDPlusRDoubleLayerBurnOption];
    }
#endif
    
    [uiView showBurnMenu];
}

- (IBAction) chooseBurnDiscFormat: sender
{
    burnType = [sender tag];

    if ( burnType == 0 ) discCapacity = MAX_CD_FILE_SIZE;
    else if ( burnType == 1 ) discCapacity = MAX_DVD_FILE_SIZE;
    else if ( burnType == 2 ) discCapacity = MAX_DVD_DOUBLE_LAYER_FILE_SIZE;
        
    [self chooseBurnFile: nil];
}

- (IBAction) chooseBurnFile: sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
    // ask the user for the file to burn. 
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel setResolvesAliases: YES];
    [openPanel setDelegate: self];
    [openPanel setTitle: @"Select The Source File For Your Master Copy"];
    [openPanel setPrompt: @"Select"];
    
CHOOSE_FILE:

    [uiView hideBurnMenu];

    if ( [openPanel runModalForTypes: nil] == NSOKButton )
    {
        isAnimating = YES;
        [uiView showAnimationBurn];
                                
        burnInfo = [[DSBurnInfo alloc] initWithFilepath: [[openPanel filenames] objectAtIndex: 0]];

        float dataPercentage = [burnInfo fileSize] / discCapacity;
        
        [animationView beginEncodingAnimationForDataPercentage: dataPercentage];
    }
    else
    {
        [uiView hideAnimationBurn];
        [uiView showMainMenu];
    }
}

- (void) encodingAnimationCompleted: (NSNotification *) note
{
    isAnimating = NO;
    [uiView hideAnimationBurn];
    [uiView showReadyToBurn];
    [self beginBurnSession: nil];
}

- (NSString *) readMePath
{
    return [[self appPath] stringByAppendingPathComponent: @"/Contents/Resources/README.TXT"];
}

- (NSString *) appPath
{
    return [[NSBundle mainBundle] bundlePath];
}

- (IBAction) beginBurnSession: sender
{
    DRFolder *rootFolder = [DRFolder virtualFolderWithName: @"TrueDisc"];
    DRFolder *trueDiscLauncherAppFolder = [DRFolder folderWithPath: [[self appPath] stringByAppendingPathComponent: @"/Contents/Resources/TrueDisc File Restore.app"]];
    DRFolder *trueDiscAppFolder = [DRFolder folderWithPath: [self appPath]];
    
    DRFile *trueDiscFile = [DRFile virtualFileWithName: @"TRUEDISC.001"
                                   dataProducer:        [DSBurnDataProvider burnDataProviderWithBurnInfo: burnInfo]];
                                   
    DRFile *trueDiscXMLFile = [DRFile virtualFileWithName: @"TRUEDISC.XML"
                                      data:                [self generateTrueDiscXMLData]];
    
    DRFile *trueDiscReadMeFile = [DRFile fileWithPath: [self readMePath]];
    
    [rootFolder addChild: trueDiscLauncherAppFolder];
    [rootFolder addChild: trueDiscAppFolder];
    [rootFolder addChild: trueDiscFile];
    [rootFolder addChild: trueDiscXMLFile];
    [rootFolder addChild: trueDiscReadMeFile];
    
    [trueDiscAppFolder setProperty:  [NSNumber numberWithBool: YES]
                       forKey:       DRInvisible
                       inFilesystem: DRAllFilesystems             ];
                  
    [trueDiscFile setSpecificName: @"TRUEDISC.001"
                  forFilesystem:   DRAllFilesystems];
                  
    [trueDiscAppFolder setSpecificName: @"TrueDiscForInstall.app"
                       forFilesystem:   DRAllFilesystems];
                  
    [trueDiscFile setProperty:  [NSNumber numberWithBool: YES]
                  forKey:       DRInvisible
                  inFilesystem: DRAllFilesystems             ];
                  
    [trueDiscXMLFile setProperty:  [NSNumber numberWithBool: YES]
                     forKey:       DRInvisible
                     inFilesystem: DRAllFilesystems             ];
                  
    DRTrack *track = [DRTrack trackForRootFolder: rootFolder];
    
    if ( track )
    {
        BOOL completedBurnSetup = NO;
        
        do {
            DRBurnSetupPanel *bsp = [DRBurnSetupPanel setupPanel];

            [bsp setDelegate: self];
            [bsp setCanSelectTestBurn: YES];
            
            if ( [bsp runSetupPanel] == NSOKButton )
            {
                DRBurn *burn = [bsp burnObject];
                
                [burn setVerifyDisc: NO];
                
                NSDictionary *deviceStatus = [[burn device] status];
                
                // verify disc is blank
                BOOL diskIsBlank = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaIsBlankKey] boolValue];
                
                if ( !diskIsBlank )
                {
                    int response = NSRunCriticalAlertPanel( @"TrueDisc only burns to new, empty discs."
                                                          , @"The disc in your CD or DVD burner already has data on it from a previous burn. To continue, you'll need to put a new disc in the drive."
                                                          , @"Try Another Disc"
                                                          , @"Cancel Burn"
                                                          , nil
                                                          ) ;
                    
                    if ( response == NSAlertDefaultReturn )
                    {
                        NSLog( @"continue" );
                        [[burn device] ejectMedia];
                        continue;
                    }
                    else if ( response == NSAlertAlternateReturn )
                    {
                        NSLog( @"break" );
                        break;
                    }
                }
                
                // verify disc is read-only
                BOOL diskIsErasable = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaIsErasableKey] boolValue];
                
                if ( diskIsErasable )
                {
                    int response = NSRunCriticalAlertPanel( @"TrueDisc only burns to read-only discs."
                                                          , @"The disc in your CD or DVD burner is erasable. To continue, you'll need to put a new disc in the drive that cannot be erased or rewritten once it's burned."
                                                          , @"Try Another Disc"
                                                          , @"Cancel Burn"
                                                          , nil
                                                          ) ;
                    
                    if ( response == NSAlertDefaultReturn )
                    {
                        NSLog( @"continue" );
                        [[burn device] ejectMedia];
                        continue;
                    }
                    else if ( response == NSAlertAlternateReturn )
                    {
                        NSLog( @"break" );
                        break;
                    }
                }
                
                // it's up to us to make sure that we don't ask the disk to burn a track that is too long
                // the Disc Recording framework will try and burn any track you give it, presumably by failing at the end of the disc
                
                uint64_t availableFreeSectors = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaFreeSpaceKey] longLongValue];
                
                 // must call -[burnInfo setStorageCapacity:] before calling -[track estimateLength] and -[burnInfo kValue]
                [burnInfo setStorageCapacity: ((availableFreeSectors * 2048) - (10 * 1024 * 1024))];
                
                uint64_t trackLengthInSectors = ( [track respondsToSelector: @selector( estimateLength )] ) ? [track estimateLength] : 0;
                
                // skip these checks on 10.2, because it doesn't support the estimateLength method
                if ( trackLengthInSectors && ( [burnInfo kValue] < 1 || trackLengthInSectors > availableFreeSectors ) ) // the latter indicates we didn't leave enough space when we called setStorageCapacity:
                {
                    int response;
                    
                    if ( [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeCDR] )
                    {
                        BOOL v = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDKey] boolValue];
                        BOOL v2 = [burnInfo canBurnToDVDOrHigher];
                        BOOL v3 = ( DRDeviceCanWriteDVDPlusRDoubleLayerKey != NULL ) ? [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue] : NO;
                        BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
                        if ( v && v2 )
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a CD-R. To continue, you'll need to put a new DVD disc in the drive."
                                                              , @"Insert Blank DVD"
                                                              , @"Cancel Burn"
                                                              , nil
                                                              ) ;
                        }
                        else if ( v3 && v4 )
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a CD-R. To continue, you'll need to put a new DVD+R double layer disc in the drive."
                                                              , @"Insert Blank DVD+R DL"
                                                              , @"Cancel Burn"
                                                              , nil
                                                              ) ;
                        }
                        else
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a single CD-R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
                                                              , @"OK"
                                                              , nil
                                                              , nil
                                                              ) ;
                            NSLog( @"break" );
                            break;
                        }
                    }
                    else if ( [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeDVDR] )
                    {
                        BOOL v3 = ( DRDeviceCanWriteDVDPlusRDoubleLayerKey != NULL ) ? [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue] : NO;
                        BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
                        if ( v3 && v4 )
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a DVD-R. To continue, you'll need to put a new DVD+R DL disc in the drive."
                                                              , @"Insert Blank DVD+R DL"
                                                              , @"Cancel Burn"
                                                              , nil
                                                              ) ;
                        }
                        else
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a single DVD-R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
                                                              , @"OK"
                                                              , nil
                                                              , nil
                                                              ) ;
                            NSLog( @"break" );
                            break;
                        }
                    }
                    else if ( DRDeviceMediaTypeDVDPlusR != NULL && [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeDVDPlusR] )
                    {
                        BOOL v3 = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue];
                        BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
                        if ( v3 && v4 )
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a DVD+R. To continue, you'll need to put a new DVD+R DL disc in the drive."
                                                              , @"Insert Blank DVD+R DL"
                                                              , @"Cancel Burn"
                                                              , nil
                                                              ) ;
                        }
                        else
                        {
                            response = NSRunCriticalAlertPanel( @"Disc too small."
                                                              , @"Your file will not fit on a single DVD+R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
                                                              , @"OK"
                                                              , nil
                                                              , nil
                                                              ) ;
                            NSLog( @"break" );
                            break;
                        }
                    }
                    else
                    {
                        response = NSRunCriticalAlertPanel( @"Unsupported media type."
                                                          , @"TrueDisc does not know how to burn to the kind of disc you've inserted."
                                                          , @"Insert Another Disc"
                                                          , @"Cancel Burn"
                                                          , nil
                                                          ) ;
                    }

                    if ( response == NSAlertDefaultReturn )
                    {
                        NSLog( @"continue" );
                        [[burn device] ejectMedia];
                        continue;
                    }
                    else if ( response == NSAlertAlternateReturn )
                    {
                        NSLog( @"break" );
                        break;
                    }
                }
                
                completedBurnSetup = YES;
                
                [[DRNotificationCenter currentRunLoopCenter] addObserver: self
                                                             selector:    @selector( burnNotification: )
                                                             name:        DRBurnStatusChangedNotification
                                                             object:      burn                           ];	
                
                DRBurnProgressPanel *bpp = [DRBurnProgressPanel progressPanel];

                [bpp setDelegate: self];
                [bpp setVerboseProgressStatus: YES];

                [uiView hideReadyToBurn];
                [uiView showBurning];
                isBurning = YES;
                
                // start the burn (this method returns before the burn is complete)
                [bpp beginProgressPanelForBurn: burn
                     layout:                    track];
            }
            else
            {   
                completedBurnSetup = YES; // user canceled the burn
                [uiView hideReadyToBurn];
                [uiView resetAll];
                [uiView showMainMenu];
                [animationView resetVisuals];
            }
        } while ( completedBurnSetup == NO );
    }
    else
    {
        [uiView showMainMenu];
        NSLog( @"TrueDisc: Problem creating the track object. Burn aborted." ); // TODO: improve me
    }
}

- (IBAction) restore: sender
{
    if ( isBurning )
    {
        [uiView resetNavigationButtons];
        return;
    }
    
    [uiView hideMainMenu];
    [uiView hideBurnMenu];
    [uiView hideBurning];
    [uiView hideReadyToBurn];
    [uiView hideAnimationBurn];
    if ( isAnimating )
    {
        isAnimating = NO;
        [animationView haltInProgressAnimation];
    }
    [animationView resetVisuals];
    
    if ( [self trueDiscIsMounted] )
    {
//        NSError *err;
        
        // load TRUEDISC.XML file into plist variable
        release( plist );
        plist = [[NSDictionary alloc] initWithContentsOfFile: @"/Volumes/TrueDisc/TRUEDISC.XML"];
        
        DLOGO( plist );
        
        if ( plist )
        {
            NSSavePanel *savePanel = [NSSavePanel savePanel];
                
            [savePanel setDelegate: self];
            [savePanel setTitle: [NSString stringWithFormat: @"Where would you like to save \"%@\"?", [self restoreFilename]]];
            [savePanel setPrompt: @"Save"];
            
            if ( [savePanel runModalForDirectory: nil file: [self restoreFilename]] == NSOKButton )
            {
                // TODO: copy TRUEDISC.001, TRUEDISC.002, etc. to save path
                burnInfo = [[DSBurnInfo alloc] initWithFilepath: @"/Volumes/TrueDisc/TRUEDISC.001"];
                
                burnInfo->k = [[plist valueForKey: @"DSEncodingFactor"] intValue];
                
                DLOGO( burnInfo );
                if ( LOG_DIAGNOSTICS )
                {
                    NSString *predictedFileLength = [NSString stringWithFormat: @"Predicted file length is %f", [[plist valueForKey: @"DSEncodedFileLength"] doubleValue]];
                    NSString *actualFileLength = [NSString stringWithFormat: @"Actual file length is %f", (double)[burnInfo fileSize]];
                    DLOGO( predictedFileLength );
                    DLOGO( actualFileLength );
                }
                
                // see if we actually encodeded the file size we said we would
                if ( [[plist valueForKey: @"DSEncodedFileLength"] doubleValue] < (double)[burnInfo fileSize] )
                {
                    // nope, so we need to adjust k
                    int k = burnInfo->k;
                    double fileSize = (double)[burnInfo fileSize];
                    double originalFileSize = [[[plist valueForKey: @"DSFileAttributes"] valueForKey: @"NSFileSize"] doubleValue];
                    
                    if ( LOG_DIAGNOSTICS )
                    {
                        NSString *originalFileLength = [NSString stringWithFormat: @"Original file length is %f", [[[plist valueForKey: @"DSFileAttributes"] valueForKey: @"NSFileSize"] doubleValue]];
                        DLOGO( originalFileLength );
                    }
                    
                    // find the k we actually used
                    while ( ( fileSize * ((double)k/(double)16.0) ) > originalFileSize )
                    {
                        k--;
                    }
                    
                    NSLog( @"TrueDisc: Correcting encoding factor from %d to %d.", burnInfo->k, k );
                    burnInfo->k = k;
                }
                
//                burnInfo->k = 12;
                
                DLOGO( burnInfo );
                
                DSTrueDiscDecoder *tdd = [[DSTrueDiscDecoder alloc] initWithBurnInfo: burnInfo];
                [tdd setOriginalFileSize: [[[plist valueForKey: @"DSFileAttributes"] valueForKey: @"NSFileSize"] doubleValue]];
                
                DLOGO( burnInfo );
                
//                LOG_DIAGNOSTICS = 0;
                
                [NSThread detachNewThreadSelector: @selector( decodeFileToPath: )
                          toTarget:                tdd
                          withObject:              [savePanel filename]         ];
            }
            else
            {
                [uiView showMainMenu];
            }
        }
        else
        {
            NSRunCriticalAlertPanel( @"There was error gathering information about this disc."
                                   , @"This is generally because the filesystem on the disc has become corrupted. Unlicensed copies of the TrueDisc software cannot recover from this error. Please license your TrueDisc software and try again."
                                   , @"OK"
                                   , nil
                                   , nil
                                   ) ;
        }
    }
    else
    {
        NSRunCriticalAlertPanel( @"You have not inserted a TrueDisc."
                               , @"Please insert a TrueDisc in your disc drive and wait for it to appear on the desktop, then try again."
                               , @"OK"
                               , nil
                               , nil
                               ) ;

        [uiView showMainMenu];
    }
}

- (void) burnNotification: (NSNotification *) note	
{
//    DRBurn* burn = [note object];
    NSDictionary* status = [note userInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscProgress"
                                          object:               [status objectForKey: DRStatusPercentCompleteKey]];
    
    NSString *statusString = [status objectForKey: DRStatusStateKey];
    
    if ( [statusString isEqualToString: DRStatusStateFailed] || [statusString isEqualToString: DRStatusStateDone] )
    {
        isBurning = NO;
        [uiView resetAll];
        [animationView resetVisuals];
    }
}

- (IBAction) license: sender
{
#ifdef LICENSE_CONTROL
    lauchLicensing();
#else
    LOG
#endif
}

- (IBAction) purchase: sender
{
    [(TrueDisc *)[NSApp delegate] showBuyPageInBrowser: nil];
}

- (IBAction) help: sender
{
    [(TrueDisc *)[NSApp delegate] showHelpInBrowser: nil];
}

- (void) deviceAppeared: (NSNotification *) note
{
    NSDictionary *info = [[note userInfo] objectForKey: DRDeviceWriteCapabilitiesKey];
    
    if ( DRDeviceCanWriteCDRKey != NULL && [[info objectForKey: DRDeviceCanWriteCDRKey] boolValue] )
        canBurnToCDR = YES;
    
    if ( DRDeviceCanWriteDVDRKey != NULL && [[info objectForKey: DRDeviceCanWriteDVDRKey] boolValue] )
        canBurnToDVDR = YES;
    
    if ( DRDeviceCanWriteDVDPlusRKey != NULL && [[info objectForKey: DRDeviceCanWriteDVDPlusRKey] boolValue] )
        canBurnToDVDPlusR = YES;
    
    if ( DRDeviceCanWriteDVDPlusRDoubleLayerKey != NULL && [[info objectForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue] )
        canBurnToDVDPlusRDoubleLayer = YES;
}

- (void) deviceDisappeared: (NSNotification *) note
{

}

#pragma mark -
#pragma mark Support Procedures

- (void) registerForDeviceNotifications
{
    [[DRNotificationCenter currentRunLoopCenter] addObserver: self
                                                 selector:    @selector( deviceAppeared: )
                                                 name:        DRDeviceAppearedNotification
                                                 object:      nil                         ];

    [[DRNotificationCenter currentRunLoopCenter] addObserver: self
                                                 selector:    @selector( deviceDisappeared: )
                                                 name:        DRDeviceDisappearedNotification
                                                 object:      nil                            ];
}

- (BOOL) discIsMounted
{
    NSArray *mountedRemovableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    
    foreach( path, mountedRemovableMedia )
    {
        if ( [path isEqualToString: @"/Volumes/TrueDisc"] ) return YES;
    }
    
    return NO;
}

- (BOOL) trueDiscIsMounted
{
    NSArray *mountedRemovableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
    
    foreach( path, mountedRemovableMedia )
    {
        if ( [path isEqualToString: @"/Volumes/TrueDisc"] ) return YES;
    }
    
    return NO;

//    BOOL exists;
//    [[NSFileManager defaultManager] fileExistsAtPath: @"/Volumes/TrueDisc" isDirectory: &exists];
//    
//    return exists;
}

// returns a path to the generated file
- (NSData *) generateTrueDiscXMLData
{
    // we need to do this so that DSEncodedFileLength and DSEncodingFactor can be set properly, below
    switch ( burnType )
    {
        case CDR:
            [burnInfo setStorageCapacity: MAX_CD_FILE_SIZE];
            break;
        case DVDRorDVDPlusR:
            [burnInfo setStorageCapacity: MAX_DVD_FILE_SIZE];
            break;
        case DVDPlusRDoubleLayer:
            [burnInfo setStorageCapacity: MAX_DVD_DOUBLE_LAYER_FILE_SIZE];
            break;
    }

	NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    [info setObject: NSFullUserName()
          forKey:    @"DSFullUserName"];
          
    [info setObject: [[NSDate date] description]
          forKey:    @"DSDiscCreationDate"     ];
          
    [info setObject: [NSString uuid]
          forKey:    @"DSDiscUUID" ];

    [info setObject: @"1"
          forKey:    @"DSTrueDiscDataFormat"];
    
    [info setObject: [[NSNumber numberWithInt: burnType] description]
          forKey:    @"DSDiscType"];
    
    [info setObject: [NSString stringWithFormat: @"%llu", [burnInfo encodedFileSize]]
          forKey:    @"DSEncodedFileLength"                                         ];
    
    [info setObject: [[NSNumber numberWithInt: [burnInfo kValue]] description]
          forKey:    @"DSEncodingFactor"];
    
    [info setObject: [burnInfo filepath]
          forKey:    @"DSOriginalFilePath"];
    
	[info setObject: [[NSFileManager defaultManager] fileAttributesAtPath: [burnInfo filepath]
                                                     traverseLink:         YES               ]
          forKey:    @"DSFileAttributes"                                                     ];
    
	NSString *error = nil;
	NSData *plistData = [NSPropertyListSerialization dataFromPropertyList: info
													 format:               NSPropertyListXMLFormat_v1_0
													 errorDescription:     &error                      ];
	if ( error )
	{
		NSLog( @"TrueDisc: The TRUEDISC.XML file could not be created. Reason: %@", error );
		[error release];
        
        return nil;
	}
	else return plistData;
}

- (NSString *) restoreFilename
{
    return [[plist valueForKey: @"DSOriginalFilePath"] lastPathComponent];
}

#pragma mark -
#pragma mark State Procedures (currently unused)

// only set UI attributes here; the state itself encodes what actions/transitions are possible
// note: there should be no conditional statements in these method implementations

ui_for_state( 1 )
{
    // A supported disc burning device in not attached.

    [uiView resetNavigationButtons];
    [uiView selectRestoreMenuItem];
    [uiView disableBurnMenuItem];
    [uiView showMainMenu];
    
    [uiView display];
}

ui_for_state( 2 )
{
    [uiView hideMainMenu];
}

ui_for_transient( 3 )
{
    // Is there a CD or DVD already mounted?
    if ( [self discIsMounted] )
    {
        go( b, 4 );
    }
    else
    {
        go( b, 5 );        
    }
}

ui_for_state( 4 )
{
    // What kind of disc is mounted?
    if ( [self discIsMounted] )
    {
        go( b, 4 );
    }
    else
    {
        go( b, 5 );        
    }
}

ui_for_state( 5 )
{
    // There are no discs mounted at this time.
}

ui_for_state( 6 )
{
    // A supported disc burning device is attached.

    [uiView resetNavigationButtons];
    [uiView selectBurnMenuItem];
    [uiView showMainMenu];
}

#pragma mark -
#pragma mark Private Support Code

- (void)
gotoState: (int) to_state
variable:  (int) variable
event:     (SEL) eventSelector
{
#ifdef DEBUG_STATECHART    
    if ( debugController )
    {
        [debugController setStateVariable: variable
                         toState:          to_state];
        
        [debugController setStateHistoryVariable: variable
                         toState:                 state_variables[variable]];
        
        
        if ( [debugController log] )
        {
            NSLog( @"Entered state %c:%00d from %@", 'A' + variable, to_state, NSStringFromSelector( eventSelector ) );
        }

        if ( [debugController step] )
        {
            NSRunInformationalAlertPanel( @"State Debug"
                                        , [NSString stringWithFormat: @"Entered state %c:%00d from %@"
                                                                    , 'A' + variable
                                                                    , to_state
                                                                    , NSStringFromSelector( eventSelector ) ]
                                        , @"OK"
                                        , nil
                                        , nil
                                        ) ;
        }
    }
    
    if ( to_state < STATE_COUNT )
    {        
#endif    
        history_state_variables[variable] = state_variables[variable];
        state_variables[variable] = to_state;

        SEL sel = state_methods[ to_state ];
        if ( [self respondsToSelector: sel] )
            objc_msgSend( self,  sel );
#ifdef DEBUG_STATECHART    
        else
            NSLog( @"No ui_for_state( %d ) defined. go( %c, %d ) called from state %00d, event: %@."
                 , to_state
                 , 'a' + variable
                 , to_state
                 , state_variables[variable]
                 , NSStringFromSelector( eventSelector )
                 ) ;
#endif

#ifdef DEBUG_STATECHART    
    }
    else
        NSLog( @"go( %c, %d ) called with a state (%d) not less than STATE_COUNT (%d) during event %@."
             , 'a' + variable
             , to_state
             , to_state
             , STATE_COUNT
             , NSStringFromSelector( eventSelector )
             ) ;
#endif    
}

@end
