//
//  DSBurnInfo.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "DSBurnInfo.h"

//#include <openssl/evp.h>

@implementation DSBurnInfo

- initWithFilepath: (NSString *) theFilepath
{
    if ( self = [super init] )
    {
        filepath = [theFilepath copy];
    }
    return self;
}

//- (NSString *)
//{
//    return [NSString stringWithFormat: @"File path is: %@\nEncoding factor: %d", filepath, k];
//}

- (NSString *) filepath
{
    return filepath;
}

- (void) setStorageCapacity: (uint64_t) theStorageCapacity
{
    storageCapacity = theStorageCapacity;
    
    [self recalculateParameters];
}

- (void) dealloc
{
    release( filepath );
    
    [super dealloc];
}

- (void) recalculateParameters
{
    // reset calculated parameters
    k = 0;
    postEncodedSize = 0;
    
    // calculate new parameters
    uint64_t fileSize = [self fileSize];
    
    uint64_t initialSectionCount = fileSize / SECTION_SIZE;
    uint64_t initialOverflowBytes = fileSize % SECTION_SIZE;
    
    if ( initialOverflowBytes != 0 )
    {  
        fileSize = fileSize + SECTION_SIZE - initialOverflowBytes;
        initialSectionCount++;
    }
    
    int i;
    for ( i = 1; i < N; i++ )
    {
        uint64_t loopSectionCount = initialSectionCount;
        
        int sectorsPerSection = i * SECTORS_PER_SECTION;
        uint64_t loopSectionCountOverflow = loopSectionCount % sectorsPerSection;
        
        if ( loopSectionCountOverflow != 0 )
        {
            loopSectionCount = loopSectionCount + sectorsPerSection - loopSectionCountOverflow;
        }
        
        uint64_t preEncodedFileSize = loopSectionCount * SECTION_SIZE;
        
        uint64_t preEncodedSections = preEncodedFileSize / i;
        
        uint64_t encodedSize = preEncodedSections * N;
        
        if ( encodedSize <= storageCapacity )
        {
            // save best-fit parameters and return
            postEncodedSize = encodedSize;
            k = i;
            break;
        }
    }
}

- (uint64_t) sizeOfFork: (DRFileFork) fork
{
    return ( fork == DRFileForkData ) ? postEncodedSize : 0; // we don't encode anything but the data fork 
}

- (uint64_t) encodedFileSize;
{
    return postEncodedSize;
}

- (uint64_t) fileSize
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

- (BOOL) canBurn
{
    return ( k > 0 ) ? YES : NO;
}

- (BOOL) canBurnToCDROrHigher
{
    return ( [self fileSize] < (( MAX_CD_FILE_SIZE / 17 ) * 16 ) ) ? YES : NO;
}

- (BOOL) canBurnToDVDOrHigher
{
    return ( [self fileSize] < (( MAX_DVD_FILE_SIZE / 17 ) * 16 ) ) ? YES : NO;
}

- (BOOL) canBurnToDVDPlusDoubleLayer
{
    return ( [self fileSize] < (( MAX_DVD_DOUBLE_LAYER_FILE_SIZE / 17 ) * 16 ) ) ? YES : NO;
}

- (int) kValue
{
    return k;
}

- (int) kValueForCD
{
    [self setStorageCapacity: MAX_CD_FILE_SIZE];
    return k;
}

- (int) kValueForDVD
{
    [self setStorageCapacity: MAX_DVD_FILE_SIZE];
    return k;
}

- (int) kValueForDVDDL
{
    [self setStorageCapacity: MAX_DVD_DOUBLE_LAYER_FILE_SIZE];
    return k;
}

- (struct EncoderInfo) encoderInfoForAddress: (uint64_t) address
{
    uint64_t section = address / ENCODED_SECTION_SIZE;
    uint32_t offset = address % ENCODED_SECTION_SIZE;

    return DSMakeEncoderInfo( section, offset );
}

- (NSImage *) iconImage
{
    return [[NSWorkspace sharedWorkspace] iconForFile: [self filepath]];
}

- (NSData *) iconData
{
    return [[self iconImage] TIFFRepresentation];
}

@end

inline
struct EncoderInfo
DSMakeEncoderInfo( uint64_t section, uint32_t offset )
{
    struct EncoderInfo encoderInfo;
    
    encoderInfo.section = section;
    encoderInfo.offset = offset;
    
    return encoderInfo;
}