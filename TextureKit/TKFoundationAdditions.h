//
//  TKFoundationAdditions.h
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


//static inline NSSize TKLargestSize(NSSizeArray sizeArray, NSUInteger arrayLength) {
//	if (arrayLength == 0) return NSZeroSize;
//	NSSize largestSize = NSZeroSize;
//	for (NSUInteger i = 0; i < arrayLength; i++) {
//		NSSize theSize = *(sizeArray + i);
//		if (theSize.width > largestSize.width && theSize.height > largestSize.height) {
//			largestSize = theSize;
//		}
//	}
//	return largestSize;
//}


@interface NSObject (TKDeepMutableCopy)

- (id)deepMutableCopy NS_RETURNS_RETAINED;

@end

struct FSRef;

@interface NSString (TKAdditions)

- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)outError;

@end

