//
//  HKNode.m
//  HLKit
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKNode.h>
#import <HLKit/HKFoundationAdditions.h>


#define HK_DEBUG 0

@interface HKNode (HKPrivate)
- (BOOL)isDescendantOfNodeOrIsEqualToNode:(HKNode *)node;
@end



@implementation HKNode

@synthesize container, parent, isVisible, isLeaf, sortDescriptors;
@dynamic showInvisibleItems;

- (id)initWithParent:(HKNode *)aParent childNodes:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
	if ((self = [super init])) {
		parent = aParent;
		container = aContainer;
		isVisible = YES;
		showInvisibleItems = NO;
		
		sortDescriptors = [aSortDescriptors retain];
		
		if (theChildren) {
			childNodes = [[NSMutableArray arrayWithArray:theChildren] retain];
			visibleChildNodes = [[NSMutableArray alloc] init];
			
			for (HKNode *child in childNodes) {
				if ([child isVisible]) [visibleChildNodes addObject:child];
			}
			[childNodes makeObjectsPerformSelector:@selector(setParent:) withObject:self];
			
			[childNodes sortUsingDescriptors:sortDescriptors];
			[visibleChildNodes sortUsingDescriptors:sortDescriptors];
		}
	}
	return self;
}


- (void)dealloc {
	container = nil;
	parent = nil;
    [childNodes release];
	[visibleChildNodes release];
	[sortDescriptors release];
    [super dealloc];
}

- (BOOL)isRootNode {
	return (parent == nil);
}


- (void)setNilValueForKey:(NSString *)key {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"isLeaf"]) {
		isLeaf = NO;
	} else if ([key isEqualToString:@"isVisible"]) {
		isVisible = NO;
	} else if ([key isEqualToString:@"showInvisibleItems"]) {
		showInvisibleItems = NO;
	} else {
		[super setNilValueForKey:key];
	}
}


- (void)initializeChildrenIfNeeded {
	if (childNodes == nil && visibleChildNodes == nil) {
		childNodes = [[NSMutableArray alloc] init];
		visibleChildNodes = [[NSMutableArray alloc] init];
	}
}


- (void)insertChildNode:(HKNode *)child atIndex:(NSUInteger)index {
	[self initializeChildrenIfNeeded];
	
	[child setParent:self];
	
    [childNodes insertObject:child atIndex:index];
	[childNodes sortUsingDescriptors:sortDescriptors];
	
	if ([child isVisible]) {
		[visibleChildNodes addObject:child];
		[visibleChildNodes sortUsingDescriptors:sortDescriptors];
	}
}



- (void)insertChildNodes:(NSArray *)newChildren atIndex:(NSUInteger)theIndex {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self initializeChildrenIfNeeded];
	
	[newChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	
    [childNodes insertObjectsFromArray:newChildren atIndex:theIndex];
	
	for (HKNode *child in childNodes) {
		if ([child isVisible]) [visibleChildNodes addObject:child];
	}
	
	[childNodes sortUsingDescriptors:sortDescriptors];
	[visibleChildNodes sortUsingDescriptors:sortDescriptors];
	
}


- (void)_removeChildrenIdenticalTo:(NSArray *)theChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[theChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	for (HKNode *child in theChildren) {
		[childNodes removeObjectIdenticalTo:child];
		[visibleChildNodes removeObjectIdenticalTo:child];
	}

}


- (void)removeChildNode:(HKNode *)child {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSUInteger index = [self indexOfChildNode:child];
    if (index != NSNotFound) {
        [self _removeChildrenIdenticalTo:[NSArray arrayWithObject:[self childNodeAtIndex:index]]];
    }
}

- (void)removeFromParent {
    [parent removeChildNode:self];
}

- (NSUInteger)indexOfChildNode:(HKNode *)child {
    return [childNodes indexOfObject:child];
}

- (NSUInteger)indexOfChildNodeIdenticalTo:(HKNode *)child {
    return [childNodes indexOfObjectIdenticalTo:child];
}

- (NSUInteger)countOfChildNodes {
    return [childNodes count];
}

- (NSArray *)childNodes {
	return [[childNodes copy] autorelease];
}

- (HKNode *)childNodeAtIndex:(NSUInteger)index {
    return [childNodes objectAtIndex:index];
}


- (NSUInteger)countOfVisibleChildNodes {
	return [visibleChildNodes count];
}

- (NSArray *)visibleChildNodes {
	return [[visibleChildNodes copy] autorelease];
}


- (HKNode *)visibleChildNodeAtIndex:(NSUInteger)index {
	return [visibleChildNodes objectAtIndex:index];
}



// -------------------------------------------------------------------------------
//	Returns YES if self is contained anywhere inside the children or children of
//	sub-nodes of the nodes contained inside the given array.
// -------------------------------------------------------------------------------
- (BOOL)isContainedInNodes:(NSArray *)nodes {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// returns YES if we are contained anywhere inside the array passed in, including inside sub-nodes
	
	for (HKNode *node in nodes) {
		if (node == self) {
			return YES;             // we found ourselves
		}
		// check all the sub-nodes
		if (![node isLeaf]) {
			if ([self isContainedInNodes:[node childNodes]]) {
				return YES;
			}
		}
	}
	return NO;
	
}

// -------------------------------------------------------------------------------
//	Returns YES if any node in the array passed in is an ancestor of ours.
// -------------------------------------------------------------------------------
- (BOOL)isDescendantOfNodes:(NSArray *)nodes {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	for (HKNode *node in nodes) {
		// check all the sub-nodes
		if (![node isLeaf]) {
			if ([self isContainedInNodes:[node childNodes]]) {
				return YES;
			}
		}
	}
	return NO;
	
}



- (BOOL)isDescendantOfNodeOrIsEqualToNode:(HKNode *)node {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (node == self) {
		return YES;
	}
	if (![node isLeaf]) {
		if ([parent isDescendantOfNodeOrIsEqualToNode:node]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)isDescendantOfNode:(HKNode *)node {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![node isLeaf]) {
		if ([parent isDescendantOfNodeOrIsEqualToNode:node]) {
			return YES;
		}
	}
	return NO;
}


- (void)setShowInvisibleItems:(BOOL)value {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	showInvisibleItems = value;
	if (!isLeaf && childNodes) {
		for (HKNode *child in childNodes) {
			if (![child isLeaf]) [child setShowInvisibleItems:showInvisibleItems];
		}
	}
}

- (BOOL)showInvisibleItems {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return showInvisibleItems;
}


- (void)setSortDescriptors:(NSArray *)aSortDescriptors {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setSortDescriptors:aSortDescriptors recursively:YES];
}


- (void)setSortDescriptors:(NSArray *)aSortDescriptors recursively:(BOOL)recursively {
#if HK_DEBUG
	NSLog(@"[%@ %@] aSortDescriptors == %@, recursively == %@; sortDescriptors == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aSortDescriptors, recursively ? @"YES" : @"NO", sortDescriptors);
#endif
	
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (!isLeaf) {
		[aSortDescriptors retain];
		[sortDescriptors release];
		sortDescriptors = aSortDescriptors;
		
		if (childNodes && recursively) {
			[childNodes makeObjectsPerformSelector:@selector(setSortDescriptors:) withObject:sortDescriptors];
		}
	}
}


- (void)recursiveSortChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (!isLeaf) {
		if (childNodes) {
#if HK_DEBUG
//		NSLog(@"[%@ %@] childNodes (before) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), childNodes);
#endif
			
			[childNodes sortUsingDescriptors:sortDescriptors];
			[visibleChildNodes sortUsingDescriptors:sortDescriptors];
			
#if HK_DEBUG
//			NSLog(@"[%@ %@] childNodes (after) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), childNodes);
#endif
			
			[childNodes makeObjectsPerformSelector:@selector(recursiveSortChildren)];
		}
	}
}


@end



