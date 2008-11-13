//
//  NSCursor+TrueDiscExtensions.m
//  TrueDisc
//
//  Created by Erich Ocean on 3/1/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "NSCursor+TrueDiscExtensions.h"


@implementation NSCursor ( TrueDiscExtensions )

+ (NSCursor *) myPointingHandCursor
{
    return [[[self alloc] initWithImage: [NSImage imageNamed: @"pointingHand"]
                          hotSpot:       NSMakePoint( 5, 0 )                 ] autorelease];
}

@end
