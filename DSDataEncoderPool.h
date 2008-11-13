//
//  DSDataEncoderPool.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@class DSBurnInfo;

struct DSBufferRange {
    char *address;
    uint32_t length;
};

@interface DSDataEncoderPool : NSObject
{
    DSBurnInfo *burnInfo;
    
    
}

- initWithBurnInfo: (DSBurnInfo *) theBurnInfo;

- (struct DSBufferRange)
getBufferRangeForAddress: (uint64_t) address
length:                   (uint32_t) length;

@end

inline
struct DSBufferRange
DSMakeBufferRange( char *address, uint32_t length );