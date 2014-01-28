//
//  TKGrayscaleFilter.h
//  Source Finagler
//
//  Created by Mark Douma on 10/20/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface TKGrayscaleFilter : CIFilter {
	CIImage			*inputImage;
	NSNumber		*redScale;
	NSNumber		*greenScale;
	NSNumber		*blueScale;
	NSNumber		*alphaScale;
	
	
}

@property (retain) NSNumber *redScale;
@property (retain) NSNumber *greenScale;
@property (retain) NSNumber *blueScale;
@property (retain) NSNumber *alphaScale;


@end
