//
//  TrueDiscDataSlice.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/27/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TrueDiscDataSlice : NSObject
{
    float size;
    float intialPosition;
    float currentPosition;
    float finalPosition;
}

- (id)
initWithSize:    (float) theSize
initialPosition: (float) theInitialPosition
finalPosition:   (float) theFinalPosition;

//- (void)
//animateWithCurve: (DSCurveType) theCurve
//duration:         (float)       duration;

@end
