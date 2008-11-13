//
//  TrueDisc.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDisc.h"
#import "TrueDiscController.h"

#import <Sparkle/Sparkle.h>
#import "UKUpdateChecker.h"

#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <errno.h>
#include <syslog.h>
#include <stdarg.h>

int LOG_DIAGNOSTICS = 0;

@implementation TrueDisc

- init
{
    if ( self = [super init] )
    {
        trueDiscController = [[TrueDiscController alloc] initWithWindowNibName: @"TrueDisc"];
        
        Class Test = NSClassFromString( @"NSArrayController" );
        
        running1030orLater = ( Test != NULL ) ? YES : NO;
        
        if ( running1030orLater )
        {
            updateChecker = [[SUUpdater alloc] init];
        }
        else
        {
            updateChecker = [[UKUpdateChecker alloc] init];
            
            // simulate the normal course of things
            [updateChecker awakeFromNib];
        }
    }   
    return self;
}

- (void) dealloc
{
    release( trueDiscController );
    release( updateChecker );
    
    [super dealloc];
}

- (BOOL)
application: (NSApplication *) theApplication
openFile:    (NSString *)      filename
{
    if ( [filename isEqualToString: @"/Volumes/TrueDisc/TRUEDISC.XML"] )
    {
        shouldBeginRestore = YES;
        if ( applicationDidFinishLaunching ) [trueDiscController restore: nil];
        return YES;
    }
    else return NO;
}

- (void) applicationDidFinishLaunching: (NSNotification *) note
{
    applicationDidFinishLaunching = YES;
    
    // should we log to a diagnostics file?
    if ( [[NSUserDefaults standardUserDefaults] boolForKey: @"log_diagnostics"] )
    {
        NSLog( @"TrueDisc is enabling diagnostic logging." );
        diagonsticLog = [self createDiagnosticLog];
        
        if ( diagonsticLog )
        {
            LOG_DIAGNOSTICS = 1;
            dup2( [diagonsticLog  fileDescriptor], STDERR_FILENO);
        }
        else
        {
            NSLog( @"TrueDisc failed to enable diagnostic logging. Error %d: %s.", errno, sys_errlist[errno] );
        }
    }
    else
    {
        NSLog( @"TrueDisc diagnostic logging is NOT enabled." );
    }
    
    // Do we have the TrueDisc installer?
    [trueDiscController showWindow: nil];
    if ( shouldBeginRestore ) [trueDiscController restore: nil];
}

- (NSFileHandle *) createDiagnosticLog
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *applicationSupportFolder = [self applicationSupportFolder];
    
    BOOL found = [fileManager fileExistsAtPath: applicationSupportFolder
                              isDirectory:	    NULL                    ];
    if ( !found )
    {
        [fileManager createDirectoryAtPath: applicationSupportFolder
                     attributes:			nil                     ];
    }

    NSString *logPath = [applicationSupportFolder stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.log", [NSDate date]]];
    
    if ( [[NSFileManager defaultManager] createFileAtPath: logPath
                                         contents:         nil
                                         attributes:       nil    ] )
    {
        return [[NSFileHandle fileHandleForWritingAtPath: logPath] retain];
    }
    else
    {
        NSLog( @"TrueDisc failed to create a file for logging at path: %@.", logPath );
        return nil;
    }
}

- (NSString *) applicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSApplicationSupportDirectory
                                                        , NSUserDomainMask
                                                        , YES
                                                        ) ;
                                                        
    NSString *basePath = ( [paths count] > 0 ) ? [paths objectAtIndex: 0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent: @"TrueDisc"];
}

- (IBAction) showHelpInBrowser: sender
{
    NSURL *url = [NSURL URLWithString: @"http://www.truedisc.com/support.html"];
    
    [[NSWorkspace sharedWorkspace] openURL: url];
}

- (IBAction) showBuyPageInBrowser: sender
{
    NSURL *url = [NSURL URLWithString: @"http://www.truedisc.com/buy.html"];
    
    [[NSWorkspace sharedWorkspace] openURL: url];
}

- (IBAction) checkForUpdates: sender
{
    if ( running1030orLater )
    {
        [(SUUpdater *)updateChecker checkForUpdates: nil];
    }
    else
    {
        [(UKUpdateChecker *)updateChecker checkForUpdates: nil];
    }
}

//- (void) verifyFECOperationAndExit
//{
//    NSData *pdf = [NSData dataWithContentsOfFile: @"/Users/ocean/Desktop/mapreduce-osdi04.pdf"];
//    NSMutableData *tmpData = [[NSMutableData alloc] initWithLength: SUPER_SECTOR_SIZE / 4]; // 32 KB
//    
//    void *fec_info = fec_new( 2, N );
//    void *tmp_sector = malloc( SECTOR_SIZE );
//    
//    void *src[2];
//    
//    src[0] = (void *)[pdf bytes];
//    src[1] = (void *)[pdf bytes] + SECTOR_SIZE;
//
//    
//    int i;
//    for ( i = 0; i < N; i++ )
//    {
//        if ( i == 1 ) continue; // make sure we're not cheating
//        
//        fec_encode( fec_info, src, tmp_sector, i, SECTOR_SIZE );
//        
//        [tmpData replaceBytesInRange: NSMakeRange( i * SECTOR_SIZE, SECTOR_SIZE )
//                 withBytes:           tmp_sector                                ];
//    }
//    
//    [tmpData writeToFile: @"/Users/ocean/Desktop/tempdata3.txt" atomically: NO];
//    
//    void *pkt[2];
//
//    pkt[0] = (void *)[tmpData bytes];
//    pkt[1] = (void *)[tmpData bytes] + ( 4 * SECTOR_SIZE ); // i.e. + 8192 bytes
//    
//    int indexes[2];
//
//    indexes[0] = 0; // i.e. 0 and 4
//    indexes[1] = 4; // i.e. 0 and 4
//
//    
//    NSMutableData *tmpData2 = [[NSMutableData alloc] init];
//    
//    fec_decode( fec_info, pkt, indexes, CELL_SIZE ); // should change pkt[0] and pkt[1] in-place
//        
//    [tmpData2 appendBytes: pkt[0]
//              length:      CELL_SIZE];
//    
//    [tmpData2 appendBytes: pkt[1]
//              length:      CELL_SIZE];
//    
//    [tmpData2 writeToFile: @"/Users/ocean/Desktop/tempdata4.txt" atomically: NO];
//        
//    fec_free( fec_info );
//    
//    exit(0);
//}
//
//- (void) verifyTrueDiscOperationAndExit
//{
//    // test things out
//    burnInfo = [[DSBurnInfo alloc] initWithFilepath: @"/Users/ocean/Desktop/Billings205.dmg"];
//    
//    [burnInfo setStorageCapacity: MAX_CD_FILE_SIZE];
//    
//    int k = [burnInfo kValue];
//    
//    DSBurnDataProvider *bdp = [DSBurnDataProvider burnDataProviderWithBurnInfo: burnInfo];
//    
//    [bdp prepareFileForBurn: nil];
//
//    uint64_t size = [bdp calculateSizeOfFile: nil
//                         fork:                DRFileForkData
//                         estimating:          NO            ];
//                         
//    if ( [[NSFileManager defaultManager]  createFileAtPath: @"/Users/ocean/Desktop/Billings205-FEC.dmg"
//                                          contents:         nil
//                                          attributes:       nil     ] )
//    {
//        NSLog( @"created file" );
//    }
//
//    NSFileHandle *saveHandle = [NSFileHandle fileHandleForWritingAtPath: @"/Users/ocean/Desktop/Billings205-FEC.dmg"];
//    NSMutableData *tmpData = [[NSMutableData alloc] initWithLength: SUPER_SECTOR_SIZE];
//    
//    int i = 0;
//    int stride = SUPER_SECTOR_SIZE;
//    while ( i < size )
//    {
//        uint32_t bytesToGo = stride;
//        
//        do {
//            uint32_t bytesWritten = [bdp produceFile: nil
//                                         fork:        DRFileForkData
//                                         intoBuffer:  (void *)[tmpData bytes]
//                                         length:      bytesToGo
//                                         atAddress:   i + stride - bytesToGo
//                                         blockSize:   2048                  ];
//            bytesToGo -= bytesWritten;
//        } while ( bytesToGo > 0 );
//        
//        [saveHandle writeData: tmpData];
//        
//        i = i + stride;
//    }
//    
//    release( tmpData );
//    release( burnInfo );
//    
//    burnInfo = [[DSBurnInfo alloc] initWithFilepath: @"/Users/ocean/Desktop/Billings205-FEC.dmg"];
//    
//    burnInfo->k = k;
//    
//    NSLog( @"decoding data now" );
//    
//    DSTrueDiscDecoder *tdd = [[DSTrueDiscDecoder alloc] initWithBurnInfo: burnInfo];
//    
//    [tdd decodeFileToPath: @"/Users/ocean/Desktop/Billings205-DECODED.dmg"];
//    
//    NSData *first = [NSData dataWithContentsOfFile: @"/Users/ocean/Desktop/177.dmg"];
//    NSData *second = [NSData dataWithContentsOfFile: @"/Users/ocean/Desktop/177-FEC.dmg"];
//    
//    if ( [first isEqual: second] )
//    {
//        NSLog( @"succeeded" );
//    }
//    else NSLog( @"failed" );
//    
//    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath: @"/Users/ocean/Desktop/Billings205-DECODED.dmg"];
//    
//    [handle truncateFileAtOffset: 19817146];
//    
//    exit(0);
//}
//
//- (void) applicationDidFinishLaunching: (NSNotification *) note
//{
//    if ( [self trueDiscIsMounted] )
//    {
//        NSError *err;
//        
//        if ( [self loadTrueDiscPlistWithError: &err] )
//        {
//            NSSavePanel *savePanel = [NSSavePanel savePanel];
//                
//            [savePanel setDelegate: self];
//            [savePanel setTitle: [NSString stringWithFormat: @"Where would you like to save \"%@\"?", [plist valueForKey: @"filename"]]];
//            [savePanel setPrompt: @"Save"];
//            
//            if ( [savePanel runModal] == NSOKButton )
//            {
//                // TODO: copy TRUEDISC.001, TRUEDISC.002, etc. to save path
//                
//            }
//        }
//        else
//        {
//            // the disc appears not to be a valid truedisc or may be damaged. Notify user.
//            [self notifyUserOfLoadTrueDiscPlistError: err];
//        }
//    }
//    else
//    {
//        // XXX: Can the user burn anything? If not, no sense in putting up the open dialog.
//        
//        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//            
//        // ask the user for the file to burn. 
//        [openPanel setAllowsMultipleSelection: NO];
//        [openPanel setCanChooseDirectories: NO];
//        [openPanel setCanChooseFiles: YES];
//        [openPanel setResolvesAliases: YES];
//        [openPanel setDelegate: self];
//        [openPanel setTitle: @"Select a file to create a master copy of."];
//        [openPanel setPrompt: @"Select"];
//        
//CHOOSE_FILE:
//
//        if ( [openPanel runModalForTypes: nil] == NSOKButton )
//        {
//            burnInfo = [[DSBurnInfo alloc] initWithFilepath: [[openPanel filenames] objectAtIndex: 0]];
//            
//            // inform the user what kind of disc they can burn to, and the damage-resistance achieved by burning to that format
//            int CDKVal = [burnInfo kValueForCD];
//            int DVDKVal = [burnInfo kValueForDVD];
//            int DVDDLKVal = [burnInfo kValueForDVDDL];
//            
//            if ( CDKVal > 0 )
//            {
//                // tell user what kind of disc to insert, or show nifty graphic doing the same
//            }
//            else if ( DVDKVal > 0 )
//            {
//            
//            }
//            else if ( DVDDLKVal > 0 )
//            {
//            
//            }
//            else
//            {
//                // the chosen file is too large to be burned to our supported disk types
//                release( burnInfo );
//                int response = NSRunCriticalAlertPanel( @"The file you've chosen is too large to be burned by TrueDisc."
//                                                      , @"TrueDisc requires files to be less than 600MB in size for CD-R, less than 4.42 GB for DVD-R or DVD+R, and less than 8.04 GB for DVD+R Double Layer."
//                                                      , @"Choose Another File"
//                                                      , @"Cancel Burn"
//                                                      , nil
//                                                      ) ;
//                                                      
//                if ( response == NSAlertDefaultReturn )
//                {
//                    goto CHOOSE_FILE;
//                }
//                else // we're done
//                {
//                    return;
//                }
//            }
//            
//            DRFolder *rootFolder = [DRFolder virtualFolderWithName: @"TrueDisc"];
//            DRFolder *trueDiscAppFolder = [DRFolder folderWithPath: @"/Users/ocean/Build/Debug/TrueDisc.app"]; // XXX change for shipping version
//            
//            DRFile *trueDiscFile = [DRFile virtualFileWithName: @"TRUEDISC.001"
//                                           dataProducer:        [DSBurnDataProvider burnDataProviderWithBurnInfo: burnInfo]];
//            
//            [rootFolder addChild: trueDiscAppFolder];
//            [rootFolder addChild: trueDiscFile];
//            
//            [trueDiscFile setSpecificName: @"TRUEDISC.001"
//                          forFilesystem:   DRAllFilesystems];
//                          
//            [trueDiscFile setProperty:  [NSNumber numberWithBool: YES]
//                          forKey:       DRInvisible
//                          inFilesystem: DRAllFilesystems             ];
//                          
//            DRTrack *track = [DRTrack trackForRootFolder: rootFolder];
//            
//            if ( track )
//            {
//                BOOL completedBurnSetup = NO;
//                
//                do {
//                    DRBurnSetupPanel *bsp = [DRBurnSetupPanel setupPanel];
//
//                    [bsp setDelegate: self];
//                    [bsp setCanSelectTestBurn: YES];
//                    [bsp setCanSelectAppendableMedia: YES];
//                    
//                    if ( [bsp runSetupPanel] == NSOKButton )
//                    {
//                        DRBurn *burn = [bsp burnObject];
//
//                        NSDictionary *deviceStatus = [[burn device] status];
//                        
//                        // verify disc is blank
//                        BOOL diskIsBlank = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaIsBlankKey] boolValue];
//                        
//                        if ( !diskIsBlank )
//                        {
//                            int response = NSRunCriticalAlertPanel( @"TrueDisc only burns to new, empty discs."
//                                                                  , @"The disc in your CD or DVD burner already has data on it from a previous burn. To continue, you'll need to put a new disc in the drive."
//                                                                  , @"Try Another Disc"
//                                                                  , @"Cancel Burn"
//                                                                  , nil
//                                                                  ) ;
//                            
//                            if ( response == NSAlertDefaultReturn )
//                            {
//                                NSLog( @"continue" );
//                                [[burn device] ejectMedia];
//                                continue;
//                            }
//                            else if ( response == NSAlertAlternateReturn )
//                            {
//                                NSLog( @"break" );
//                                break;
//                            }
//                        }
//                        
//                        // verify disc is read-only
//                        BOOL diskIsErasable = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaIsErasableKey] boolValue];
//                        
//                        if ( diskIsErasable )
//                        {
//                            int response = NSRunCriticalAlertPanel( @"TrueDisc only burns to read-only discs."
//                                                                  , @"The disc in your CD or DVD burner is erasable. To continue, you'll need to put a new disc in the drive that cannot be erased or rewritten once it's burned."
//                                                                  , @"Try Another Disc"
//                                                                  , @"Cancel Burn"
//                                                                  , nil
//                                                                  ) ;
//                            
//                            if ( response == NSAlertDefaultReturn )
//                            {
//                                NSLog( @"continue" );
//                                [[burn device] ejectMedia];
//                                continue;
//                            }
//                            else if ( response == NSAlertAlternateReturn )
//                            {
//                                NSLog( @"break" );
//                                break;
//                            }
//                        }
//                        
//                        // it's up to us to make sure that we don't ask the disk to burn a track that is too long
//                        // the Disc Recording framework will try and burn any track you give it, presumably by failing at the end of the disc
//                        
//                        uint64_t availableFreeSectors = [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaFreeSpaceKey] longLongValue];
//                        
//                         // must call -[burnInfo setStorageCapacity:] this before calling -[track estimateLength] and -[burnInfo kValue]
//                        [burnInfo setStorageCapacity: ((availableFreeSectors * 2048) - (10 * 1024 * 1024))];
//                        
//                        uint64_t trackLengthInSectors = [track estimateLength];
//                        
//                        if ( [burnInfo kValue] < 1 || trackLengthInSectors > availableFreeSectors ) // the latter indicates we didn't leave enough space when we called setStorageCapacity:
//                        {
//                            int response;
//                            
//                            if ( [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeCDR] )
//                            {
//                                BOOL v = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDKey] boolValue];
//                                BOOL v2 = [burnInfo canBurnToDVDOrHigher];
//                                BOOL v3 = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue];
//                                BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
//                                if ( v && v2 )
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a CD-R. To continue, you'll need to put a new DVD disc in the drive."
//                                                                      , @"Insert Blank DVD"
//                                                                      , @"Cancel Burn"
//                                                                      , nil
//                                                                      ) ;
//                                }
//                                else if ( v3 && v4 )
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a CD-R. To continue, you'll need to put a new DVD+R double layer disc in the drive."
//                                                                      , @"Insert Blank DVD+R DL"
//                                                                      , @"Cancel Burn"
//                                                                      , nil
//                                                                      ) ;
//                                }
//                                else
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a single CD-R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
//                                                                      , @"OK"
//                                                                      , nil
//                                                                      , nil
//                                                                      ) ;
//                                    NSLog( @"break" );
//                                    break;
//                                }
//                            }
//                            else if ( [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeDVDR] )
//                            {
//                                BOOL v3 = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue];
//                                BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
//                                if ( v3 && v4 )
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a DVD-R. To continue, you'll need to put a new DVD+R DL disc in the drive."
//                                                                      , @"Insert Blank DVD+R DL"
//                                                                      , @"Cancel Burn"
//                                                                      , nil
//                                                                      ) ;
//                                }
//                                else
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a single DVD-R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
//                                                                      , @"OK"
//                                                                      , nil
//                                                                      , nil
//                                                                      ) ;
//                                    NSLog( @"break" );
//                                    break;
//                                }
//                            }
//                            else if ( [[[deviceStatus valueForKey: DRDeviceMediaInfoKey] valueForKey: DRDeviceMediaTypeKey] isEqualToString: DRDeviceMediaTypeDVDPlusR] )
//                            {
//                                BOOL v3 = [[[[[burn device] info] valueForKey: DRDeviceWriteCapabilitiesKey] valueForKey: DRDeviceCanWriteDVDPlusRDoubleLayerKey] boolValue];
//                                BOOL v4 = [burnInfo canBurnToDVDPlusDoubleLayer];
//                                if ( v3 && v4 )
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a DVD+R. To continue, you'll need to put a new DVD+R DL disc in the drive."
//                                                                      , @"Insert Blank DVD+R DL"
//                                                                      , @"Cancel Burn"
//                                                                      , nil
//                                                                      ) ;
//                                }
//                                else
//                                {
//                                    response = NSRunCriticalAlertPanel( @"Disc too small."
//                                                                      , @"Your file will not fit on a single DVD+R disc. You can reduce the file size before burning or split the file into multiple parts and try again."
//                                                                      , @"OK"
//                                                                      , nil
//                                                                      , nil
//                                                                      ) ;
//                                    NSLog( @"break" );
//                                    break;
//                                }
//                            }
//                            else
//                            {
//                                response = NSRunCriticalAlertPanel( @"Unsupported media type."
//                                                                  , @"TrueDisc does not know how to burn to the kind of disc you've inserted."
//                                                                  , @"Insert Another Disc"
//                                                                  , @"Cancel Burn"
//                                                                  , nil
//                                                                  ) ;
//                            }
//
//                            if ( response == NSAlertDefaultReturn )
//                            {
//                                NSLog( @"continue" );
//                                [[burn device] ejectMedia];
//                                continue;
//                            }
//                            else if ( response == NSAlertAlternateReturn )
//                            {
//                                NSLog( @"break" );
//                                break;
//                            }
//                        }
//                        
//                        completedBurnSetup = YES;
//                        
//                        [[DRNotificationCenter currentRunLoopCenter] addObserver: self
//                                                                     selector:    @selector( burnNotification: )
//                                                                     name:        DRBurnStatusChangedNotification
//                                                                     object:      burn                           ];	
//                        
//                        //
//                        // this is how to conditionalize code based on the presence of the symbol
//                        //
//                        
//    //                    if ( SymbolName != NULL)
//    //                    {
//    //                        printf("SymbolName is present!\n");
//    //                        SymbolName();
//    //                    }
//
//                        DRBurnProgressPanel *bpp = [DRBurnProgressPanel progressPanel];
//
//                        [bpp setDelegate: self];
//                        [bpp setVerboseProgressStatus: YES];
//
//                        // start the burn (this method returns before the burn is complete)
//                        [bpp beginProgressPanelForBurn: burn
//                             layout:                    track];
//                    }
//                    else completedBurnSetup = YES; // user canceled the burn
//                } while ( completedBurnSetup == NO );
//            }
//            else NSLog( @"TrueDisc: Problem creating the track object. Burn aborted." ); // TODO: improve me
//        }
//    }
//}
//
//- (void) burnNotification: (NSNotification *) note	
//{	
////    DRBurn* burn = [note object];
////    NSDictionary* status = [note userInfo];
////
////    LOGO( status );
//}
//
//- (BOOL) trueDiscIsMounted
//{
//    // TODO: write me
//    return NO;
//}
//
//- (BOOL) loadTrueDiscPlistWithError: (NSError **) error
//{
//    // TODO: write me
//    return NO;
//}
//
//- (void) notifyUserOfLoadTrueDiscPlistError: (NSError *) error
//{
//    // if software is licensed and the file just couldn't be read, we can offer to fix it for them by hard-mounting the disc
//    // and entering the disc's special code
//    
//    // TODO: write me
//}
//
//// returns a path to the generated file
//- (NSData *) generateTrueDiscXMLData
//{
//	NSMutableDictionary *info = [NSMutableDictionary dictionary];
//    
//    [info setObject: NSFullUserName()
//          forKey:    @"DSFullUserName"];
//          
//    [info setObject: [[NSDate date] description]
//          forKey:    @"DSDiscCreationDate"     ];
//          
//    [info setObject: [NSString uuid]
//          forKey:    @"DSDiscUUID" ];
//
//    [info setObject: @"1"
//          forKey:    @"DSTrueDiscDataFormat"];
//    
////    [info setObject: [/* the format of the disc -- CD-R, DVD-R, DVD+R, etc. */]
////          forKey:    @"DSDiscType"];
//    
//    [info setObject: [NSString stringWithFormat: @"%llu", [burnInfo encodedFileSize]]
//          forKey:    @"DSEncodedFileLength"                                         ];
//    
//    [info setObject: [[NSNumber numberWithInt: [burnInfo kValue]] description]
//          forKey:    @"DSEncodingFactor"];
//    
//    [info setObject: [burnInfo filepath]
//          forKey:    @"DSOriginalFilePath"];
//    
//	[info setObject: [[NSFileManager defaultManager] fileAttributesAtPath: [burnInfo filepath]
//                                                     traverseLink:         YES               ]
//          forKey:    @"DSFileAttributes"                                                     ];
//			
//	NSString *error = nil;
//	NSData *plistData = [NSPropertyListSerialization dataFromPropertyList: info
//													 format:               NSPropertyListXMLFormat_v1_0
//													 errorDescription:     &error                      ];
//	if ( error )
//	{
//		NSLog( @"TrueDisc: The TRUEDISC.XML file could not be created. Reason: %@", error );
//		[error release];
//        
//        return nil;
//	}
//	else return plistData;
//}

@end
