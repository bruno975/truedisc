//
//  TrueDiscLogoView.m
//  TrueDisc
//
//  Created by Erich Ocean on 3/1/07.
//  Copyright 2007 Erich Atlas Ocean. All rights reserved.
//

#import "TrueDiscLogoView.h"


@implementation TrueDiscLogoView

- initWithFrame: (NSRect) frameRect
{
    if ( self = [super initWithFrame: frameRect] )
    {
        NSString *logoPath = [[NSBundle mainBundle] pathForImageResource: @"truedisc-logo.pdf"];
        NSURL *url = [[[NSURL alloc] initFileURLWithPath: logoPath] autorelease]; 
        document = CGPDFDocumentCreateWithURL( (CFURLRef)url );
        page = CGPDFDocumentGetPage( document, 1 );
    }
    return self;
}

- (void) dealloc
{
    CGPDFPageRelease( page );
    CGPDFDocumentRelease( document );
    
    [super dealloc];
}

- (BOOL) isOpaque { return NO; }

- (BOOL) acceptsFirstResponder { return NO; }

- (void)
drawRect:(NSRect)aRect;
{
	CGRect cgRect = NSRectToCGRect( [self bounds] );
	
	CGContextRef gContext = [[NSGraphicsContext currentContext] graphicsPort];

	CGContextSetInterpolationQuality( gContext, kCGInterpolationHigh );
	CGContextSetShouldAntialias( gContext, true );
	CGContextSetRenderingIntent( gContext, kCGRenderingIntentDefault );
	CGContextSetShouldSmoothFonts( gContext, true );
	CGContextSetFlatness( gContext, 1.0 );
	
	CGRect mediaBox = CGPDFPageGetBoxRect( page, kCGPDFMediaBox );
	CGAffineTransform myTransform = GetDrawingTransformToCenterAndScaleSourceRectInDestinationRect(	mediaBox, cgRect, true );
	
	// draw pdf page
	CGContextConcatCTM( gContext, myTransform );
	
	CGContextDrawPDFPage ( gContext, page );
}

@end

CGAffineTransform
GetDrawingTransformToCenterAndScaleSourceRectInDestinationRect(
		CGRect src,
		CGRect dst,
		int preserveAspectRatio
	)
{
	CGAffineTransform transform = { 1, 0, 0, 1, 0, 0 }; // the identity transform
	CGPoint srcCenter  = CGPointMake( src.origin.x + (src.size.width/2), src.origin.y + (src.size.height/2) );
	CGPoint dstCenter = CGPointMake( dst.origin.x + (dst.size.width/2), dst.origin.y + (dst.size.height/2) );
	float xScale;
	float yScale;
	
	if ( src.size.width != 0.0 ) xScale = dst.size.width / src.size.width; else return transform;
	if ( src.size.height != 0.0 ) yScale = dst.size.height / src.size.height; else return transform;
	
	if ( preserveAspectRatio )
	{
		// first, figure out which dimension of dst is closest to src
		if ( fabs( xScale ) < fabs( yScale ) )
		{
			// width is closest, so we'll scale the width as the "control" scale
			transform.a = xScale;
			transform.d = xScale;
			transform.tx = dstCenter.x - (srcCenter.x * xScale);
			transform.ty = dstCenter.y - (srcCenter.y * xScale);
		}
		else 
		{
			// height is closest, so we'll scale the height as the "control" scale
			transform.a = yScale;
			transform.d = yScale;
			transform.tx = dstCenter.x - (srcCenter.x * yScale);
			transform.ty = dstCenter.y - (srcCenter.y * yScale);
		}
	}
	else
	{
		// scale each dimension independently
		transform.a = xScale;
		transform.d = yScale;
	}
	
	return transform;
}
