//
//  DSBurnDataProvider.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "DSBurnDataProvider.h"
#import "DSBurnInfo.h"

#import "fec.h"

#ifdef LICENSE_CONTROL
#import <LicenseControl/DetermineOpMode.h>
#endif

@implementation DSBurnDataProvider

+ burnDataProviderWithBurnInfo: (DSBurnInfo *) theBurnInfo
{
    return [[[self alloc] initWithBurnInfo: theBurnInfo] autorelease];
}

- initWithBurnInfo: (DSBurnInfo *) theBurnInfo
{
    if ( self = [super init] )
    {
        burnInfo = theBurnInfo; // weak retain
        
        encodedSectionIndex = -1; // so that we can do encoding the very first time
    }
    return self;
}

- (void) dealloc
{
    release( encodedData );
    release( sourceData );
    release( sourceFile );
    
    if ( encoder_info ) fec_free( encoder_info );
    if ( encoded_sector ) free( encoded_sector );

    [super dealloc];
}

- (BOOL) prepareFileForBurn: (DRFile *) file
{
#ifdef LICENSE_CONTROL
    if ( OpModeLicensed != licensingLevelCheck().opMode )
    {
        if ( [burnInfo fileSize] > MAXIMUM_UNLICENSED_FILE_SIZE )
        {
            NSRunCriticalAlertPanel( @"TrueDisc is unlicensed. Cancelling burn."
                                   , @"TrueDisc only burns files up to 5 MB in size in unlicensed mode. If you believe you have gotten this message in error, please contact TrueDisc technical support."
                                   , @"OK"
                                   , nil
                                   , nil
                                   ) ;

            return NO;
        }
    }
#endif
    
    if ( [burnInfo canBurn] ) // sanity check
    {
        int k = [burnInfo kValue];
        
        encodedData = [[NSMutableData alloc] initWithLength: ENCODED_SECTION_SIZE];
        
        for ( sectionsInEachStride = 1; sectionsInEachStride < 1000; sectionsInEachStride++ )
        {
            sectionStride = SECTION_SIZE * k * sectionsInEachStride;
            
            if ( sectionStride > ( 256 * 1024 ) ) break;
        }
        
        sourceFile = [[NSFileHandle fileHandleForReadingAtPath: [burnInfo filepath]] retain];
        
        encoder_info = fec_new( k, N );
        
        encoded_sector = malloc( SECTOR_SIZE );
            
        if ( encodedData && sourceFile && encoder_info && encoded_sector)
        {
            // load first section
            sectionAtStartOfSourceData = 0; // index from zero
            
//            NSLog ( @"reading section %llu", sectionAtStartOfSourceData );

            NS_DURING
                sourceData = [[sourceFile readDataOfLength: sectionStride] retain];
                
            NS_HANDLER
                NSLog( @"TrueDisc: an error occurred reading file data from disk." );
                
                release( encodedData );
                release( sourceData );
                release( sourceFile );
                
                if ( encoder_info ) fec_free( encoder_info );
                if ( encoded_sector ) free( encoded_sector );

                NS_VALUERETURN( NO, BOOL );
                
            NS_ENDHANDLER
            
            if ( [sourceData length] < sectionStride )
            {
                [sourceData autorelease];
                sourceData = [sourceData mutableCopy];

//                NSLog ( @"extending source data for section %llu", sectionAtStartOfSourceData );
                    
                [sourceData setLength: sectionStride];
            }
                // extends to the full length of sectionStride (if needed), filling bytes with zero
                // this allows us to avoid worrying about data we need past the end of the file
                // NSFileHandle returns an empty NSData when it reach EOF, and truncates the returned data when
                // it reaches EOF the first time.
            
            return YES;
        }
        else
        {
            release( encodedData );
            release( sourceData );
            release( sourceFile );
            
            if ( encoder_info ) fec_free( encoder_info );
            if ( encoded_sector ) free( encoded_sector );

            return NO;
        }
    }
    else return NO;
}

- (uint64_t)
calculateSizeOfFile: (DRFile *)   file
fork:                (DRFileFork) fork 
estimating:          (BOOL)       estimate
{
    return [burnInfo sizeOfFork: (DRFileFork) fork]; // this is exact when the disk capacity is known
}
        

- (uint32_t)
produceFile: (DRFile *)   file
fork:        (DRFileFork) fork 
intoBuffer:  (char *)     buffer
length:      (uint32_t)   bufferLength
atAddress:   (uint64_t)   address
blockSize:   (uint32_t)   blockSize
{
//    LOG
    
    if ( fork != DRFileForkData ) return 0;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    char *bufferAddress = buffer;
    uint32_t lengthWritten = 0;
    struct DSBufferRange bufferRange = DSMakeBufferRange( NULL, 0 );
    
//    NSLog( @"requested data at address %llu", address );
    
    bufferRange = [self getBufferRangeForAddress: ( address + lengthWritten )
                        length:                   ( bufferLength - lengthWritten )];
                               
    if ( bufferRange.length > 0 )
    {
        if ( bufferRange.length > bufferLength ) bufferRange.length = bufferLength;
        
        // copy bufferRange into our buffer
        memcpy( bufferAddress, bufferRange.address, bufferRange.length );
        
        bufferAddress += bufferRange.length;
        lengthWritten += bufferRange.length;
    }
    
    [pool release];
    
    return lengthWritten;
}
        
- (void) cleanupFileAfterBurn: (DRFile *) file
{

}

- (struct DSBufferRange)
getBufferRangeForAddress: (uint64_t) address
length:                   (uint32_t) length
{
    struct EncoderInfo encoderInfo = [burnInfo encoderInfoForAddress: address];
    
//    NSNumber *num = [NSNumber numberWithLongLong: encoderInfo.section];
//    NSLog( @"encoderInfo.section = %@", num );
//    NSLog( @"encoderInfo.offset = %d", encoderInfo.offset );
    
    // Do we even have the section loaded from disk?
    if ( sectionAtStartOfSourceData <= encoderInfo.section && encoderInfo.section < sectionAtStartOfSourceData + sectionsInEachStride )
    {
        // Have we already encoded data for this section?
        if ( encoderInfo.section == sectionAtStartOfSourceData + encodedSectionIndex )
        {
            // return as much of the requested data as possible
            return DSMakeBufferRange( [encodedData bytes] + encoderInfo.offset, [encodedData length] - encoderInfo.offset );
        }
        else
        {
            // encode the section
            [self encodeSectionAtIndex: encoderInfo.section - sectionAtStartOfSourceData];
            
            // return as much of the requested data as possible
            return DSMakeBufferRange( [encodedData bytes] + encoderInfo.offset, [encodedData length] - encoderInfo.offset );
        }
    }
    else
    {   
        // we need to load the section's source data from disc
        release( sourceData );
        
        do {
            NS_DURING
                sectionAtStartOfSourceData += sectionsInEachStride;
                
//                NSLog ( @"reading section %llu", sectionAtStartOfSourceData );

                sourceData = [[sourceFile readDataOfLength: sectionStride] retain];

                if ( [sourceData length] < sectionStride )
                {
                    [sourceData autorelease];
                    sourceData = [sourceData mutableCopy];
                    
                    NSLog ( @"extending source data for section %llu", sectionAtStartOfSourceData );
                    
                    [sourceData setLength: sectionStride];
                }
                // extends to the full length of sectionStride (if needed), filling bytes with zero
                // this allows us to avoid worrying about data we need past the end of the file
                // NSFileHandle returns an empty NSData when it reach EOF, and truncates the returned data when
                // it reaches EOF the first time.
                
            NS_HANDLER
                NSLog( @"TrueDisc: an error occurred reading file data from disk." );

                struct DSBufferRange bufferRange = DSMakeBufferRange( 0, 0 );
                
                NS_VALUERETURN( bufferRange, struct DSBufferRange );
                
            NS_ENDHANDLER
            
        } while ( !((sectionAtStartOfSourceData + sectionsInEachStride) > encoderInfo.section && encoderInfo.section >= sectionAtStartOfSourceData) );
        
        // encode the section
        [self encodeSectionAtIndex: encoderInfo.section - sectionAtStartOfSourceData];
        
        // return as much of the requested data as possible
        return DSMakeBufferRange( [encodedData bytes] + encoderInfo.offset, [encodedData length] - encoderInfo.offset );
    }
}

- (void) encodeSectionAtIndex: (int) index
{
    encodedSectionIndex = index;
    
    //
    // this is the actual FEC encode
    //
    
    int k = [burnInfo kValue];
    
//    NSLog( @"k is %d", k );
    
    const char *source_block_base = [sourceData bytes] + ( SECTION_SIZE * k * index );
    
    int j;
    int encoded_block_index, encoded_sector_index;
    
    // encode k consecutive sectors each for four loops
    for ( encoded_block_index = 0; encoded_block_index < INTERLEAVE; encoded_block_index++ )
    {
        const char *source_block = source_block_base + ( SECTOR_SIZE * k * encoded_block_index );
        
        void *source_sectors[ MAX_K ]; // currently 15, not all pointers will be filled if k < 15
        
        // set k sector pointers of size 2048 bytes
        for ( j = 0; j < k; j++ )
        {
            void *sector_pointer = (void *)( source_block + ( j * SECTOR_SIZE ) );
            
//            NSLog( @"sector pointer %p", sector_pointer );
            
            source_sectors[ j ] = sector_pointer;
        }
        
//        NSLog( @"generating encoded sectors" );
//        NSLog( @"encodedData length is %d", [encodedData length] );
        
        // generate N (16) encoded sectors from j source sectors, copying the encoded cells into encodedData
        for ( encoded_sector_index = 0; encoded_sector_index < N; encoded_sector_index++ )
        {
            // THIS NEEDS TO CHANGE TO USE CELL_SIZE INSTEAD OF SECTOR_SIZE
            fec_encode( encoder_info, source_sectors, encoded_sector, encoded_sector_index, SECTOR_SIZE );
            
            // copy cells to correct disc location
            int encoded_cell_index;
            for ( encoded_cell_index = 0; encoded_cell_index < INTERLEAVE; encoded_cell_index++ )
            {
                // there are 64 disc sectors we put cells in
                unsigned int offset = block_offset( encoded_cell_index )
                                    + sector_offset( ( encoded_sector_index * INTERLEAVE ) - ( ( encoded_sector_index / INTERLEAVE ) * ( N - 1 ) ) )
                                    + cell_offset( encoded_block_index )
                                    ;
                
                [encodedData replaceBytesInRange: NSMakeRange( offset, CELL_SIZE )
                             withBytes:           encoded_sector + cell_offset( encoded_cell_index )];
            }
        }

//        // copy cells to correct disc location
//        int encoded_cell_index;
//        for ( encoded_cell_index = 0; encoded_cell_index < INTERLEAVE; encoded_cell_index++ )
//        {
//            // adjust source_sectors pointers to point to next cell index each round
//            void *source_cells[ MAX_K ];
//            
//            for ( j = 0; j < MAX_K; j++ )
//            {
//                source_cells[ j ] = source_sectors[ j ] + ( CELL_SIZE * encoded_cell_index );
//            }
//            
//            // generate N (16) encoded sectors from j source sectors, copying the encoded cells into encodedData
//            for ( encoded_sector_index = 0; encoded_sector_index < N; encoded_sector_index++ )
//            {
//                fec_encode( encoder_info, source_cells, encoded_sector + cell_offset( encoded_cell_index ), encoded_sector_index, CELL_SIZE );
//
//                // there are 64 disc sectors we put cells in
//                unsigned int offset = block_offset( encoded_cell_index )
//                                    + sector_offset( ( encoded_sector_index * INTERLEAVE ) - ( ( encoded_sector_index / INTERLEAVE ) * ( N - 1 ) ) )
//                                    + cell_offset( encoded_block_index )
//                                    ;
//                
////                NSLog( @"offset is %d", offset );
//                
//                [encodedData replaceBytesInRange: NSMakeRange( offset, CELL_SIZE )
//                             withBytes:           encoded_sector + cell_offset( encoded_cell_index )];
//            }
//        }
    }
    
//    static BOOL onlyOnce = YES;
//    
//    if ( onlyOnce )
//    {   
//        NSLog( @"writing data" );
//        [encodedData writeToFile: @"/Users/ocean/Desktop/tempdata.txt" atomically: NO];
//        onlyOnce = NO;
//    }
}

@end

inline int block_offset( int block) { return block * SECTOR_SIZE * N; }
inline int sector_offset( int sector) { return sector * SECTOR_SIZE; }
inline int cell_offset( int cell ) { return cell * CELL_SIZE; }

inline
struct DSBufferRange
DSMakeBufferRange( const char *address, uint32_t length )
{
    struct DSBufferRange bufferRange;
    
    bufferRange.address = address;
    bufferRange.length = length;
    
    return bufferRange;
}