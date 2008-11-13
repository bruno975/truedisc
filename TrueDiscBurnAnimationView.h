//
//  TrueDiscBurnAnimationView.h
//  TrueDisc
//
//  Created by Erich Ocean on 2/28/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

@interface TrueDiscBurnAnimationView : NSView
{
    IBOutlet NSTextField *readingFileDataText;
    IBOutlet NSTextField *generatingEncodingDataText;
    IBOutlet NSTextField *interleavingDataText;
    
    NSString *readingFileDataString;
    NSString *generatingEncodingDataString;
}

- (void) beginFileReadingStage: (NSNotification *) note;
- (void) beginDataEncodingStage: (NSNotification *) note;
- (void) beginDataInterleavingStage: (NSNotification *) note;

@end
