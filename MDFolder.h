//
//  MDFolder.h
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDItem.h"


@interface MDFolder : MDItem {
	NSUInteger			countOfVisibleChildren;
	
@private
	void *_privateData;
	
}

- (MDItem *)descendantAtPath:(NSString *)aPath;

- (NSDictionary *)visibleDescendantsAndPathsRelativeToItem:(MDItem *)parentItem;

@end
