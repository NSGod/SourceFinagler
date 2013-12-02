//
//  TKImageViewPrivateInterfaces.m
//  Source Finagler
//
//  Created by Mark Douma on 8/28/2013.
//  Copyright (c) 2013 Mark Douma. All rights reserved.
//

#import "TKImageViewPrivateInterfaces.h"



CGColorRef TKCreateGrayBackgroundColor() {
	const CGFloat components[] = {0.500023, 0.500023, 0.500023, 1.0};
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	CGColorRef color = CGColorCreate(colorSpaceRef, components);
	CGColorSpaceRelease(colorSpaceRef);
	return color;
}
