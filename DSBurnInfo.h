//
//  DSBurnInfo.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

struct EncoderInfo {
    uint64_t section;
    uint32_t offset;
};

@interface DSBurnInfo : NSObject
{
    NSString *filepath;
    uint64_t storageCapacity;
    uint64_t postEncodedSize;
    
    @public
    int k;
}

- initWithFilepath: (NSString *) theFilepath;

- (uint64_t) sizeOfFork: (DRFileFork) fork;

- (void) recalculateParameters;

- (BOOL) canBurn;
- (BOOL) canBurnToCDROrHigher;
- (BOOL) canBurnToDVDOrHigher;
- (BOOL) canBurnToDVDPlusDoubleLayer;

- (int) kValue;
- (int) kValueForCD;
- (int) kValueForDVD;
- (int) kValueForDVDDL;

- (uint64_t) encodedFileSize;
- (uint64_t) sizeOfFork: (DRFileFork) fork;
- (uint64_t) fileSize;
- (void) setStorageCapacity: (uint64_t) theStorageCapacity;

- (struct EncoderInfo) encoderInfoForAddress: (uint64_t) address;

- (NSString *) filepath;

- (NSData *) iconData;

@end

inline
struct EncoderInfo
DSMakeEncoderInfo( uint64_t section, uint32_t offset );

#define KB 1024
#define MB (1024 * KB)
#define GB (1024 * MB)

#define MAX_CD_FILE_SIZE ((650 * MB) - (10 * MB))
#define MAX_DVD_FILE_SIZE (4700000000 - (10 * MB))
#define MAX_DVD_DOUBLE_LAYER_FILE_SIZE (8550000000 - (10 * MB))

// the two parameters you may want to adjust
#define N GF_BITS
#define INTERLEAVE 4

#define MAX_K (N - 1)

#define SECTOR_SIZE (2 * KB)
#define CELL_SIZE (SECTOR_SIZE / INTERLEAVE)

#define SECTORS_PER_SECTION INTERLEAVE
#define SECTION_SIZE (SECTOR_SIZE * SECTORS_PER_SECTION)
#define ENCODED_SECTION_SIZE (SECTION_SIZE * N)

// i.e. 128 KB
#define SUPER_SECTOR_SIZE ENCODED_SECTION_SIZE

// i.e. 256 cells
#define CELLS_PER_SUPER_SECTOR (SUPER_SECTOR_SIZE / CELL_SIZE)

#define MAXMIMUM_FILE_SIZE 2013265920 // = 15/16 of 2GB or 1.875 GB
#define MAXIMUM_UNLICENSED_FILE_SIZE ( 5 * MB )

