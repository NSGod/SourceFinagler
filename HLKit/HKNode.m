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

#define HK_USE_BLOCKS 0

#if HK_USE_BLOCKS
#else
#endif


@implementation HKNode

@synthesize container, parent, isVisible, isLeaf, sortDescriptors;
@dynamic showInvisibleItems;

- (id)initWithParent:(HKNode *)aParent children:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
	if ((self = [super init])) {
		parent = aParent;
		container = aContainer;
		isVisible = YES;
		showInvisibleItems = NO;
		
		sortDescriptors = [aSortDescriptors retain];
		
		if (theChildren) {
			children = [[NSMutableArray arrayWithArray:theChildren] retain];
			visibleChildren = [[NSMutableArray alloc] init];
			
#if HK_USE_BLOCKS
			[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *child, NSUInteger idx, BOOL *stop) {
				[child setParent:self];
				if ([child isVisible]) [visibleChildren addObject:child];
			}];
#else
			for (HKNode *child in children) {
				if ([child isVisible]) [visibleChildren addObject:child];
			}
			[children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
#endif
			
			[children sortUsingDescriptors:sortDescriptors];
			[visibleChildren sortUsingDescriptors:sortDescriptors];
		}
	}
	return self;
}


- (void)dealloc {
	container = nil;
	parent = nil;
    [children release];
	[visibleChildren release];
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
	if (children == nil && visibleChildren == nil) {
		children = [[NSMutableArray alloc] init];
		visibleChildren = [[NSMutableArray alloc] init];
	}
}


- (void)insertChild:(HKNode *)child atIndex:(NSUInteger)index {
	[self initializeChildrenIfNeeded];
	
	[child setParent:self];
	
    [children insertObject:child atIndex:index];
	[children sortUsingDescriptors:sortDescriptors];
	
	if ([child isVisible]) {
		[visibleChildren addObject:child];
		[visibleChildren sortUsingDescriptors:sortDescriptors];
	}
}



- (void)insertChildren:(NSArray *)newChildren atIndex:(NSUInteger)theIndex {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self initializeChildrenIfNeeded];
	
//#if HK_USE_BLOCKS
//	[newChildren enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *node, NSUInteger anIndex, BOOL *stop) {
//		[node setParent:self];
//	}];
//#else
	[newChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
//#endif
	
    [children insertObjectsFromArray:newChildren atIndex:theIndex];
	
//#if HK_USE_BLOCKS
//	[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *node, NSUInteger idx, BOOL *stop) {
//		if ([node isVisible]) [visibleChildren addObject:node];
//	}];
//#else
	for (HKNode *child in children) {
		if ([child isVisible]) [visibleChildren addObject:child];
	}
//#endif
	
	[children sortUsingDescriptors:sortDescriptors];
	[visibleChildren sortUsingDescriptors:sortDescriptors];
	
}


- (void)_removeChildrenIdenticalTo:(NSArray *)theChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
#if HK_USE_BLOCKS
	[theChildren enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *node, NSUInteger idx, BOOL *stop) {
		[node setParent:nil];
		[children removeObjectIdenticalTo:node];
		[visibleChildren removeObjectIdenticalTo:node];
	}];
#else
	[theChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	for (HKNode *child in theChildren) {
		[children removeObjectIdenticalTo:child];
		[visibleChildren removeObjectIdenticalTo:child];
	}
#endif

}


- (void)removeChild:(HKNode *)child {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSUInteger index = [self indexOfChild:child];
    if (index != NSNotFound) {
        [self _removeChildrenIdenticalTo:[NSArray arrayWithObject:[self childAtIndex:index]]];
    }
}

- (void)removeFromParent {
    [parent removeChild:self];
}

- (NSUInteger)indexOfChild:(HKNode *)child {
    return [children indexOfObject:child];
}

- (NSUInteger)indexOfChildIdenticalTo:(HKNode *)child {
    return [children indexOfObjectIdenticalTo:child];
}

- (NSUInteger)countOfChildren {
    return [children count];
}

- (NSArray *)children {
	return [[children copy] autorelease];
}

- (HKNode *)childAtIndex:(NSUInteger)index {
    return [children objectAtIndex:index];
}


- (NSUInteger)countOfVisibleChildren {
	return [visibleChildren count];
}

- (NSArray *)visibleChildren {
	return [[visibleChildren copy] autorelease];
}


- (HKNode *)visibleChildAtIndex:(NSUInteger)index {
	return [visibleChildren objectAtIndex:index];
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
	
#if HK_USE_BLOCKS
	__block BOOL isContained = NO;
	
	[nodes enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *node, NSUInteger idx, BOOL *stop) {
		if (node == self) isContained = YES;
		if (isContained) {
			if (stop) *stop = YES;
		}
		
		if (![node isLeaf]) {
			isContained = [self isContainedInNodes:[node children]];
			if (isContained) {
				if (stop) *stop = YES;
			}
		}
	}];
	
	return isContained;
	
#else
	for (HKNode *node in nodes) {
		if (node == self) {
			return YES;             // we found ourselves
		}
		// check all the sub-nodes
		if (![node isLeaf]) {
			if ([self isContainedInNodes:[node children]]) {
				return YES;
			}
		}
	}
	return NO;
#endif
	
}

// -------------------------------------------------------------------------------
//	Returns YES if any node in the array passed in is an ancestor of ours.
// -------------------------------------------------------------------------------
- (BOOL)isDescendantOfNodes:(NSArray *)nodes {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
#if HK_USE_BLOCKS
	__block BOOL isDescendant = NO;
	
	[nodes enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *node, NSUInteger idx, BOOL *stop) {
		// check all the sub-nodes
		if (![node isLeaf]) {
			isDescendant = [self isContainedInNodes:[node children]];
		}
	}];
	return isDescendant;
	
#else
	for (HKNode *node in nodes) {
		// check all the sub-nodes
		if (![node isLeaf]) {
			if ([self isContainedInNodes:[node children]]) {
				return YES;
			}
		}
	}
	return NO;
#endif
	
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
	if (!isLeaf && children) {
#if HK_USE_BLOCKS
		[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *child, NSUInteger idx, BOOL *stop) {
			if (![child isLeaf]) [child setShowInvisibleItems:showInvisibleItems];
		}];
#else
		for (HKNode *child in children) {
			if (![child isLeaf]) [child setShowInvisibleItems:showInvisibleItems];
		}
#endif
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
		
#if HK_USE_BLOCKS
		[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *child, NSUInteger idx, BOOL *stop) {
			[child setSortDescriptors:sortDescriptors recursively:YES];
		}];
#else
		if (children && recursively) {
			[children makeObjectsPerformSelector:@selector(setSortDescriptors:) withObject:sortDescriptors];
		}
#endif
	}
}


- (void)recursiveSortChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (!isLeaf) {
		if (children) {
#if HK_DEBUG
//		NSLog(@"[%@ %@] children (before) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), children);
#endif
			
			[children sortUsingDescriptors:sortDescriptors];
			[visibleChildren sortUsingDescriptors:sortDescriptors];
			
#if HK_DEBUG
//			NSLog(@"[%@ %@] children (after) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), children);
#endif
			
#if HK_USE_BLOCKS
			[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKNode *child, NSUInteger idx, BOOL *stop) {
				[child recursiveSortChildren];
			}];
#else
			[children makeObjectsPerformSelector:@selector(recursiveSortChildren)];
#endif
		}
	}
}


@end



