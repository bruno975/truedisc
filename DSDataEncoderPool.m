//
//  DSDataEncoderPool.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/18/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "DSDataEncoderPool.h"
#import "DSDataEncoder.h"
#import "DSBurnInfo.h"


@implementation DSDataEncoderPool

- initWithBurnInfo: (DSBurnInfo *) theBurnInfo
{
    if ( self = [super init] )
    {
        burnInfo = theBurnInfo; // weak retain
    }
    return self;
}

- (struct DSBufferRange)
getBufferRangeForAddress: (uint64_t) address
length:                   (uint32_t) length
{
    struct EncoderInfo encoderInfo = [burnInfo encoderInfoForAddress: address];
    
    DSDataEncoder *dataEncoder = [self dataEncoderForSection: encoderInfo.section];
    
/*
    
Okay, so the basic idea here is that the *completed* data encoder for a given section can be looked up by number from a dictionary. As long as they are in the dictionary, data encoders are guaranteed to always have complete, encoded data for their section.

What if there isn't one in the dictionary? Then we need to check our free list of data encoders that can be reused to encode the requested section. There is a lot of criteria we could use for choosing a given data encoder, and it might be worthwhile to develop a comparison function and then keep all data encoders in a priority queue with that comparison function.

If no data encoders are available to be reused, we simply return and hope one becomes available next time we're called. This should happen rarely, if ever, in practice.

To make a specific data encoder acquire a new section, you must first invalidate its current buffer (so that it won't be used), remove it from the dictionary of "active" encoders, and then send in to the DSDataBufferPool to be assigned a source data buffer.

Note that the enqueue operation requires a lock. We'll use an OSSpinLock since we expect contention to be low (only the burn thread and the data encoder launcher thread access the lock).

*/
    

    return DSMakeBufferRange( 0, 0 );
}

@end

inline
struct DSBufferRange
DSMakeBufferRange( char *address, uint32_t length )
{
    struct DSBufferRange bufferRange;
    
    bufferRange.address = address;
    bufferRange.length = length;
    
    return bufferRange;
}