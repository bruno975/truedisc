//
//  DSTrueDiscDecoder.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/20/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "DSTrueDiscDecoder.h"
#import "DSBurnInfo.h"

#import "fec.h"

@implementation DSTrueDiscDecoder

- (id)
initWithBurnInfo: (DSBurnInfo *) theBurnInfo
{
    if ( self = [super init] )
    {
        dataWritten = 0;
        
        burnInfo = theBurnInfo; // weak retain

        decoder_info = fec_new( [theBurnInfo kValue], N );
        
        bscIndex = MakeDiscSuperSectorCellIndexToBlockSectorCellMapping();
        
        BOOL allocation_failed = NO;
        
        int i, j;
        for ( i = 0; i < N; i++ )
        {
            struct DSEncodedCell cell = encoded_cells[ i ];
            
            cell.data = [[NSMutableData alloc] initWithLength: MAX_K * CELL_SIZE];
            
            if ( !cell.data )
            {
                allocation_failed = YES;
                break;
            }
            
            void *base = (void *)[cell.data bytes];
                        
            for ( j = 0; j < MAX_K; j++ )
            {
                cell.cell_pointers[ j ] = base + ( j * CELL_SIZE );
            }
            
            encoded_cells[ i ] = cell;
        }
        
        if ( !( burnInfo || decoder_info || encoded_cells || bscIndex || allocation_failed ) )
        {
            if ( decoder_info ) fec_free( decoder_info );
            if ( encoded_cells ) free( encoded_cells );
            if ( bscIndex ) free( bscIndex );
            
            for ( i = 0; i < N; i++ )
            {
                struct DSEncodedCell cell = encoded_cells[ i ];
                
                release ( cell.data );
            }
            
            [self autorelease]; // I think this is right...
            
            return nil;
        }
    }   
    return self;
}

- (void) dealloc
{
    if ( decoder_info ) fec_free( decoder_info );
    if ( bscIndex ) free( bscIndex );

    [super dealloc];
}

- (void) setOriginalFileSize: (double) fileSize
{
    originalFileSize = fileSize;
}

- (void) removeFileAtPath: (NSString *) filepath
{
    [[NSFileManager defaultManager] removeFileAtPath: filepath
                                    handler:          nil     ];
}

- (void) decodeFileToPath: (NSString *) filepath // assumed to be absolute
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    DLOGO( burnInfo );
                
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    uint64_t fileSize = [burnInfo fileSize]; 
    int total_super_sectors = fileSize / SUPER_SECTOR_SIZE;
    
    if ( fileSize == 0 || fileSize < (128 * KB) || ( fileSize % SUPER_SECTOR_SIZE ) != 0 )
    {
        NSLog( @"TrueDisc: file system reported on-disc file size as %llu bytes, which is incorrect. Aborting extraction.", fileSize );
    }
    
    NSFileHandle *fileHandle = [[NSFileHandle fileHandleForReadingAtPath: [burnInfo filepath]] retain];
    
    if ( !fileHandle )
    {
        NSLog( @"TrueDisc: failed to open the on-disc file for reading. Aborting extraction." );
        return;
    }
    
    NSFileHandle *saveHandle = [[self saveHandleForPath: filepath
                                      result:            results] retain]; // handles creating the file if necessary, or truncating an existing file
    
    
    if ( !saveHandle )
    {
        NSLog( @"TrueDisc: failed to create or open the file for writing at (&@). Aborting extraction.", filepath );
        return;
    }
    
    int k = [burnInfo kValue];
//    int error_rate = N - k;
    int i, j;
    
    DLOG( @"total super sectors is %d", total_super_sectors );

    // for each  encoded super sector of 128 KB
    int sector_index;
    for ( sector_index = 0; sector_index < total_super_sectors; sector_index++ )
    {
        [pool release];
        pool = [[NSAutoreleasePool alloc] init];

        // referesh our data structures
        for ( i = 0; i < N; i++ )
        {
            struct DSEncodedCell cell = encoded_cells[ i ];
            
            cell.count = 0;
            
            for ( j = 0; j < MAX_K; j++ )
            {
                cell.indexes[ j ] = 0;
            }
            
            encoded_cells[ i ] = cell;
        }
        
        DLOG( @"TrueDisc: reading super sector %d.", sector_index );
        
        // for each consecutive cell in the super sector
        for ( j = 0; j < CELLS_PER_SUPER_SECTOR; j++ )
        {
            struct DSBlockSectorCell bsc = (struct DSBlockSectorCell)bscIndex[ j ]; // get which cell this was in the non-interleaved encoding layout

            DLOG( @"%d:%d:%d", bsc.block, bsc.sector, bsc.cell );
            int cell_index = ( bsc.block * 4 ) + bsc.cell;
            struct DSEncodedCell *cell = &encoded_cells[ cell_index ];
            
            if ( cell->count >= k )
            {
                DLOG( @"continuing" );
                continue; // don't read the cell, we've already read enough cells to reconstruct the source data
            }
            
//            NSLog( @"%d:%d:%d", bsc.block, bsc.sector, bsc.cell );
            
            // try and read the cell from disc
            NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
            
            unsigned long long offset = ( (unsigned long long)sector_index * SUPER_SECTOR_SIZE ) + ( (unsigned long long)j * CELL_SIZE );
            
            DLOG(@"seeking to offset %d", offset );
            
            NS_DURING
                [fileHandle seekToFileOffset: offset];

            NS_HANDLER
                NSLog( @"TrueDisc: could not seek to file offset %llu at super sector %d; aborting.", offset, sector_index );
                
                [fileHandle release];
                [saveHandle release];
                [self removeFileAtPath: filepath];
                NS_VOIDRETURN;
                // TODO: add this information the results dictionary
                
            NS_ENDHANDLER
            
            NS_DURING
                NSData *cellData = [fileHandle readDataOfLength: CELL_SIZE];
                
//                if ( j % 3 == 0 )
//                {
//                    NSLog( @"skipping damaged cell at index %d", j );
//                    continue;
//                }
                
                if ( [cellData length] == CELL_SIZE ) // sanity check
                {
                    DLOG( @"reading cell at index %d", j );

                    // okay, we've successfully read the cell
                    void *encoded_cell_pointer = cell->cell_pointers[ cell->count ];
                    
                    DLOG( @"%@", cellData );
                    
                    DLOG( @"writing cell data at %p", encoded_cell_pointer );

                    [cellData getBytes: encoded_cell_pointer];
                    
                    DLOG( @"bsc.sector = %d", bsc.sector );
                    
                    cell->indexes[ cell->count ] = bsc.sector; // this is the index of N for this cell in this decode set
                    cell->count++;
                }
                else
                {
                    NSLog( @"TrueDisc: could not read all of a cell in super sector %d; aborting.", sector_index );

                    [fileHandle release];
                    [saveHandle release];
                    [self removeFileAtPath: filepath];
                    [pool2 release];
                    [pool release];
                    NS_VOIDRETURN;
                    // TODO: add this information the results dictionary
                }
                
            NS_HANDLER
                NSLog( @"TrueDisc: could not read a cell in super sector %d; aborting.", sector_index );
                
                [fileHandle release];
                [saveHandle release];
                [self removeFileAtPath: filepath];
                [pool2 release];
                [pool release];
                NS_VOIDRETURN;
                // TODO: add this information the results dictionary
                
            NS_ENDHANDLER
            
            [pool2 release];
        }
        
        // for each horizontal set of cell/sectors in each block of the super_sector
        
        DLOG( @"k is %d", k);
        
        NSMutableData *decodedData = [[NSMutableData alloc] initWithLength: k * SECTOR_SIZE * INTERLEAVE]; // e.g. if k = 2, 16 KB
        
        int g;
        for ( g = 0; g < INTERLEAVE; g++ )
        {
            int cell_index;
            for ( cell_index = 0; cell_index < INTERLEAVE; cell_index++ )
            {
                int actual_cell_index =  (g * INTERLEAVE) + cell_index;
                
                DLOG( @"actual_cell_index = %d", actual_cell_index );
                
                struct DSEncodedCell *cell = &encoded_cells[ actual_cell_index ];
                
                if ( cell->count >= k )
                {
                    // decode the cells in place, then append decoded data to our saveHandle
                    fec_decode( decoder_info, cell->cell_pointers, cell->indexes, CELL_SIZE );
                    
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    //
                    // THIS IS WHAT NEEDS TO BE FIXED: PARTIAL SECTORS ARE BEING WRITTEN IMPROPERTLY TO THE FILE (i.e. OUT OF ORDER)
                    //
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    
                    int h;
                    for ( h = 0; h < k; h++ )
                    {
                        // this is a start, but doesn't actually work; you're too tired to program right now
                        int destination_sector_offset = ( h * SECTOR_SIZE ) + ( g * k * SECTOR_SIZE );
                        int destination_cell_offset = cell_index * CELL_SIZE;
                        int destination_offset = destination_sector_offset + destination_cell_offset;
                        
                        void *source_cell_offset = (void *)[cell->data bytes] + ( h * CELL_SIZE );
                        
                        DLOG( @"destination_sector_offset is %d", destination_sector_offset );
                        DLOG( @"destination_cell_offset is %d", destination_cell_offset );
                        DLOG( @"= %d", destination_offset );
                        DLOG( @"source_cell_offset is %p", source_cell_offset );
                        DLOG( @"================================================" );
                        
                        [decodedData replaceBytesInRange: NSMakeRange( destination_offset, CELL_SIZE )
                                     withBytes:           source_cell_offset                         ];
                    }

                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                }
                else
                {
//                    NSRunCriticalAlertPanel( @"The disc was too damaged to restore all of the data."
//                                           , @"Missing data has been zeroed in the file copy. You should make sure your copy of TrueDisc is up to date; we regularly improve our recovery algorithms."
//                                           , @"OK"
//                                           , nil
//                                           , nil
//                                           ) ;
                    
                    NSLog( @"TrueDisc: disc was too damaged to read all of the data. Erased bytes have been zeroed in the file copy. Super sector %d, cell %d", sector_index, cell_index );
                    // we can't get the data, so append all of the good bytes individually, and zero the missing bytes
                    // record this in the results dictionary
                    
                }
            }
        }
        
        DLOG( @"**** writing data of length %d ****", [decodedData length] );

        dataWritten += [decodedData length];
        
        float percentage = dataWritten / originalFileSize;
        if ( percentage > 1.0 ) percentage = 1.0;
        
        [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscProgress"
                                              object:               [NSNumber numberWithFloat: percentage]];
        
        NS_DURING
            [saveHandle writeData: decodedData];

        NS_HANDLER
            NSLog( @"TrueDisc: could not write to file at super sector %d; aborting.", sector_index );
            
            [decodedData release];
            [fileHandle release];
            [saveHandle release];
            [self removeFileAtPath: filepath];
            [pool release];
            NS_VOIDRETURN;
            // TODO: add this information the results dictionary
            
        NS_ENDHANDLER
        
        [decodedData release];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName: @"TrueDiscProgress"
                                          object:               [NSNumber numberWithFloat: 0.0]];

    [pool release];
    
    NS_DURING
        [saveHandle truncateFileAtOffset: originalFileSize];

    NS_HANDLER
        NSLog( @"TrueDisc: could not truncate the output file at offset %llu; aborting.", (unsigned long long)originalFileSize );
        
        [fileHandle release];
        [saveHandle release];
        [self removeFileAtPath: filepath];
        NS_VOIDRETURN;
        // TODO: add this information the results dictionary
        
    NS_ENDHANDLER
    
    [fileHandle release];
    [saveHandle release];
}

- (NSFileHandle *)
saveHandleForPath: (NSString *) filepath
result: (NSMutableDictionary *) results
{
    if ( [[NSFileManager defaultManager]  fileExistsAtPath: filepath] )
    {
        NSFileHandle *saveHandle = [NSFileHandle fileHandleForWritingAtPath: filepath];
        
        if ( saveHandle ) return saveHandle;
        else
        {
            // TODO: deal with the errors
            return nil;
        }
    }
    else
    {
        if ( [[NSFileManager defaultManager]  createFileAtPath: filepath
                                              contents:         nil
                                              attributes:       nil     ] )
        {
            NSFileHandle *saveHandle = [NSFileHandle fileHandleForWritingAtPath: filepath];
            
            if ( saveHandle ) return saveHandle;
            else
            {
                // TODO: deal with the errors
                return nil;
            }
        }
        else
        {
            // TODO: deal with errors
            return nil;
        }
    }
}

@end

struct DSBlockSectorCell *
MakeDiscSuperSectorCellIndexToBlockSectorCellMapping()
{
    // IMPORTANT: this should exactly mirror code in DSBurnDataProvider
    
    struct DSBlockSectorCell *bsc = malloc( sizeof( struct DSBlockSectorCell ) * INTERLEAVE * N * INTERLEAVE ); // i.e. * 256
    
    if ( bsc )
    {
        int encoded_block_index, encoded_sector_index, encoded_cell_index;
        
        for ( encoded_block_index = 0; encoded_block_index < INTERLEAVE; encoded_block_index++ )
        {
            for ( encoded_sector_index = 0; encoded_sector_index < N; encoded_sector_index++ )
            {
                for ( encoded_cell_index = 0; encoded_cell_index < INTERLEAVE; encoded_cell_index++ )
                {
                    int block_offset2 = block_offset( encoded_cell_index );
                    int sector_offset2 = sector_offset( ( encoded_sector_index * INTERLEAVE ) - ( ( encoded_sector_index / INTERLEAVE ) * ( N - 1 ) ) );
                    int cell_offset2 = cell_offset( encoded_block_index );
                    
                    int offset_in_super_sector = ( ( block_offset2 + sector_offset2 + cell_offset2 ) / CELL_SIZE ); // in range 0 - 255
                    
                    // these are the locations written to by the encoding algorithm for the sectors (in order)
                    // we'll write these to a table that we can index into to retrieve the encoded block, sector, and cell for a given disc cell
                    
                    bsc[ offset_in_super_sector ] = DSMakeBlockSectorCell( encoded_block_index, encoded_sector_index, encoded_cell_index );
                    
//                    NSLog( @"offset at %d is for %d:%d:%d", offset_in_super_sector, encoded_block_index, encoded_sector_index, encoded_cell_index );
                }
            }
        }
    }
    return bsc;
}

inline
struct DSBlockSectorCell
DSMakeBlockSectorCell( int block, int sector, int cell )
{
    struct DSBlockSectorCell bsc;
    
    bsc.block = block;
    bsc.sector = sector;
    bsc.cell = cell;
    
    return bsc;
}