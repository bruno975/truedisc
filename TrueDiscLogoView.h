//
//  TrueDiscLogoView.h
//  TrueDisc
//
//  Created by Erich Ocean on 3/1/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscView.h"

@interface TrueDiscLogoView : TrueDiscView
{
    CGPDFDocumentRef document;
	CGPDFPageRef page;
}

@end

CGAffineTransform
GetDrawingTransformToCenterAndScaleSourceRectInDestinationRect(
		CGRect sourceRect,
		CGRect destinationRect,
		int preserveAspectRatio
	);
	
#define NSRectToCGRect( aRect ) CGRectMake(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height)
#define CGRectToNSRect( aRect ) NSMakeRect(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height)


