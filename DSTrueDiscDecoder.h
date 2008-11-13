//
//  DSTrueDiscDecoder.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/20/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "DSBurnDataProvider.h"
#import "DSBurnInfo.h"

@class DSBurnInfo;

struct DSBlockSectorCell {
    int block;
    int sector;
    int cell;
};

struct DSEncodedCell {
    int count; // same as dynamic length of cell_indexes and *cells
    int indexes[ MAX_K ];
    
    void *cell_pointers[ MAX_K ]; // these pointers are initialize to point into data, below, sequentially
                          // fec_decode will straighten it all out and we can then append to a file
    
    NSMutableData *data;
};

@interface DSTrueDiscDecoder : NSObject
{
    DSBurnInfo * burnInfo;
    
    void * decoder_info;
    
    double dataWritten;
    double originalFileSize;
    
    struct DSBlockSectorCell * bscIndex;
    
    // this is a BIG inline struct, with no embedded pointers
    struct DSEncodedCell encoded_cells[ INTERLEAVE * INTERLEAVE ];
}

- (id)
initWithBurnInfo: (DSBurnInfo *) theBurnInfo;

- (void) setOriginalFileSize: (double) fileSize;

- (void) decodeFileToPath: (NSString *) filepath;

- (NSFileHandle *)
saveHandleForPath: (NSString *) filepath
result: (NSMutableDictionary *) results;

@end

struct DSBlockSectorCell *
MakeDiscSuperSectorCellIndexToBlockSectorCellMapping();

inline
struct DSBlockSectorCell
DSMakeBlockSectorCell( int block, int sector, int cell );
