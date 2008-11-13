//
//  NSColor+TrueDiscExtensions.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/25/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "NSColor+TrueDiscExtensions.h"


@implementation NSColor ( TrueDiscExtensions )

+ trueDiscBlue
{
    return [NSColor colorWithDeviceRed: 0.33333333333
                    green:              0.65098039216
                    blue:               0.94509803922
                    alpha:              1.0          ];
}

+ trueDiscDarkBlue
{
    return [NSColor colorWithDeviceRed: 0.28333333333
                    green:              0.60098039216
                    blue:               0.89509803922
                    alpha:              1.0          ];
}

+ trueDiscLightBlue
{
    return [NSColor colorWithDeviceRed: 0.38333333333
                    green:              0.70098039216
                    blue:               0.99509803922
                    alpha:              1.0          ];
}

@end
