//
//  TrueDiscBurnAnimationView.m
//  TrueDisc
//
//  Created by Erich Ocean on 2/28/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscBurnAnimationView.h"


@implementation TrueDiscBurnAnimationView

- (void) awakeFromNib
{
    NSArray *textFields = [NSArray arrayWithObjects: readingFileDataText, generatingEncodingDataText, interleavingDataText, nil];
    NSColor *fadedWhite = [NSColor colorWithDeviceWhite: 1.0 alpha: 0.3];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: fadedWhite];
    }
    
    [[self window] resetCursorRects];
    
    readingFileDataString = [[readingFileDataText stringValue] copy];
    generatingEncodingDataString = [[generatingEncodingDataText stringValue] copy];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector:    @selector( beginFileReadingStage: )
                                          name:        @"TrueDiscBeginFileReadingStage"
                                          object:      nil                               ];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector:    @selector( beginDataEncodingStage: )
                                          name:        @"TrueDiscBeginDataEncodingStage"
                                          object:      nil                                ];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector:    @selector( beginDataInterleavingStage: )
                                          name:        @"TrueDiscBeginDataInterleavingStage"
                                          object:      nil                                    ];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector:    @selector( resetAnimation: )
                                          name:        @"TrueDiscEncodingAnimationCompleted"
                                          object:      nil                                    ];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector:    @selector( resetAnimation: )
                                          name:        @"TrueDiscResetAnimation"
                                          object:      nil                        ];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                          name:           nil
                                          object:         nil ];
    
    release( readingFileDataString );
    release( generatingEncodingDataString );
    
    [super dealloc];
}

- (void) resetAnimation: (NSNotification *) note
{
    [readingFileDataText setStringValue: readingFileDataString];
    [generatingEncodingDataText setStringValue: generatingEncodingDataString];

    NSArray *textFields = [NSArray arrayWithObjects: readingFileDataText, generatingEncodingDataText, interleavingDataText, nil];
    NSColor *fadedWhite = [NSColor colorWithDeviceWhite: 1.0 alpha: 0.3];
    
    foreach( textField, textFields )
    {
        [textField setTextColor: fadedWhite];
    }
}

- (void) beginFileReadingStage: (NSNotification *) note
{
    [readingFileDataText setTextColor: [NSColor trueDiscBlue]];
}

- (void) beginDataEncodingStage: (NSNotification *) note
{
    [readingFileDataText setStringValue: [[readingFileDataText stringValue] stringByAppendingString: @"done"]];
    [readingFileDataText setTextColor: [NSColor whiteColor]];
    [generatingEncodingDataText setTextColor: [NSColor trueDiscBlue]];
}

- (void) beginDataInterleavingStage: (NSNotification *) note
{
    [generatingEncodingDataText setStringValue: [[generatingEncodingDataText stringValue] stringByAppendingString: @"done"]];
    [generatingEncodingDataText setTextColor: [NSColor whiteColor]];
    [interleavingDataText setTextColor: [NSColor trueDiscBlue]];
}

@end
