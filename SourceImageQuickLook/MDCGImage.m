//
//  MDCGImage.m
//  Source Finagler
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#include "MDCGImage.h"

#define MD_DEBUG 1


CGImageRef MDCGImageCreateCopyWithSize(CGImageRef imageRef, CGSize size) {
	CGImageRef newImageRef = NULL;
	size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
	size_t newBytesPerRow = (bytesPerRow * size.width)/CGImageGetWidth(imageRef);
	CGFloat adjustedNewBytesPerRow = ceil((CGFloat)newBytesPerRow/16.0) * 16.0;
	//	size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
	//	NSLog(@"old image %ld x %ld, bytesPerRow == %ld, bitsPerComponent == %lu; newImage == %f x %f, newBytesPerRow == %ld, adjustedNewBytesPerRow == %f", CGImageGetWidth(imageRef), CGImageGetHeight(imageRef),  bytesPerRow, bitsPerComponent, size.width, size.height, newBytesPerRow, adjustedNewBytesPerRow);
	
	void *bitmapData = malloc(adjustedNewBytesPerRow * size.height);
	if (bitmapData) {
		//		CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
		CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
		
		//		NSLog(@"bitmapInfo == %u, alphaInfo == %u, OR'd == %u", bitmapInfo, alphaInfo, bitmapInfo | alphaInfo);
		
		CGContextRef context = CGBitmapContextCreate(bitmapData,
													 size.width,
													 size.height,
													 CGImageGetBitsPerComponent(imageRef),
													 adjustedNewBytesPerRow,
													 CGImageGetColorSpace(imageRef),
													 (alphaInfo & kCGImageAlphaNone) ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast);
		
		if (context) {
			CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), imageRef);
			newImageRef = CGBitmapContextCreateImage(context);
			CGContextRelease(context);
		}
		free(bitmapData);
	} else {
		NSLog(@"MDCGImageCreateCopyWithSize(): malloc() failed!");
	}
	return newImageRef;
}

	
