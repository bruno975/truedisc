//
//  NSString+DSExtensions.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/23/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "NSString+DSExtensions.h"


@implementation NSString ( DSExtensions )

+ (NSString *) uuid
{
    CFUUIDRef theUUID = CFUUIDCreate( NULL );
    CFStringRef string = CFUUIDCreateString( NULL, theUUID );
    CFRelease( theUUID );
    return [(NSString *)string autorelease];
}

@end
