//
//  HKFolder.h
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKItem.h>


@interface HKFolder : HKItem {
	NSUInteger			countOfVisibleChildren;
	
@private
	void *_privateData;
	
}

- (HKItem *)descendantAtPath:(NSString *)aPath;

- (NSDictionary *)visibleDescendantsAndPathsRelativeToItem:(HKItem *)parentItem;

@end
