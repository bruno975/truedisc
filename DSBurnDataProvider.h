//
//  DSBurnDataProvider.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class DSBurnInfo;

struct DSBufferRange {
    const char *address;
    uint32_t length;
};

@interface DSBurnDataProvider : NSObject
{
    DSBurnInfo    * burnInfo;
    NSMutableData * encodedData;
    NSMutableData * sourceData;
    NSFileHandle  * sourceFile;
    
    int sectionStride;
    int sectionsInEachStride;
    uint64_t sectionAtStartOfSourceData;
    int encodedSectionIndex;
    
    void * encoder_info;
    void * encoded_sector;
}

+ burnDataProviderWithBurnInfo: (DSBurnInfo *) theBurnInfo;

- initWithBurnInfo: (DSBurnInfo *) theBurnInfo;

- (uint64_t)
calculateSizeOfFile: (DRFile *)   file
fork:                (DRFileFork) fork 
estimating:          (BOOL)       estimate;
        

- (BOOL) prepareFileForBurn: (DRFile *) file; 

- (uint32_t)
produceFile: (DRFile *)   file
fork:        (DRFileFork) fork 
intoBuffer:  (char *)     buffer
length:      (uint32_t)   bufferLength
atAddress:   (uint64_t)   address
blockSize:   (uint32_t)   blockSize; 
        
- (void) cleanupFileAfterBurn: (DRFile *) file;

- (struct DSBufferRange)
getBufferRangeForAddress: (uint64_t) address
length:                   (uint32_t) length;

- (void) encodeSectionAtIndex: (int) index;

@end

inline
struct DSBufferRange
DSMakeBufferRange( const char *address, uint32_t length );

inline int block_offset( int block);
inline int sector_offset( int sector);
inline int cell_offset( int cell );
