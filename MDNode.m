//
//  MDNode.m
//  Source Finagler
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDNode.h"
#import "MDFoundationAdditions.h"


#define MD_DEBUG 0

@interface MDNode (MDPrivate)
- (BOOL)isDescendantOfNodeOrIsEqualToNode:(MDNode *)node;
@end


@implementation MDNode

@synthesize container, parent, isVisible, isLeaf, sortDescriptors;
@dynamic showInvisibleItems;

- (id)initWithParent:(MDNode *)aParent children:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
	if ((self = [super init])) {
		parent = aParent;
		container = aContainer;
		isVisible = YES;
		showInvisibleItems = NO;
		
		sortDescriptors = [aSortDescriptors retain];
		
		if (theChildren) {
			children = [[NSMutableArray arrayWithArray:theChildren] retain];
			visibleChildren = [[NSMutableArray alloc] init];
			for (MDNode *child in children) {
				if ([child isVisible]) [visibleChildren addObject:child];
			}
			[children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
			
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
#if MD_DEBUG
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


- (void)insertChild:(MDNode *)child atIndex:(NSUInteger)index {
	[self initializeChildrenIfNeeded];
	
	[child setParent:self];
	
    [children insertObject:child atIndex:index];
	[children sortUsingDescriptors:sortDescriptors];
	
	if ([child isVisible]) {
		[visibleChildren addObject:child];
		[visibleChildren sortUsingDescriptors:sortDescriptors];
	}
}



- (void)insertChildren:(NSArray *)newChildren atIndex:(NSUInteger)index {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self initializeChildrenIfNeeded];

	[newChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	
    [children insertObjectsFromArray:newChildren atIndex:index];
	
	for (MDNode *child in children) {
		if ([child isVisible]) {
			[visibleChildren addObject:child];
		}
	}
	
	[children sortUsingDescriptors:sortDescriptors];
	[visibleChildren sortUsingDescriptors:sortDescriptors];
	
}


- (void)_removeChildrenIdenticalTo:(NSArray *)theChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	[theChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	for (MDNode *child in theChildren) {
		[children removeObjectIdenticalTo:child];
		[visibleChildren removeObjectIdenticalTo:child];
	}
}


- (void)removeChild:(MDNode *)child {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSUInteger index = [self indexOfChild:child];
    if (index != NSNotFound) {
        [self _removeChildrenIdenticalTo:[NSArray arrayWithObject:[self childAtIndex:index]]];
    }
}

- (void)removeFromParent {
    [parent removeChild:self];
}

- (NSUInteger)indexOfChild:(MDNode *)child {
    return [children indexOfObject:child];
}

- (NSUInteger)indexOfChildIdenticalTo:(MDNode *)child {
    return [children indexOfObjectIdenticalTo:child];
}

- (NSUInteger)countOfChildren {
    return [children count];
}

- (NSArray *)children {
	return [[children copy] autorelease];
}

- (MDNode *)childAtIndex:(NSUInteger)index {
    return [children objectAtIndex:index];
}


- (NSUInteger)countOfVisibleChildren {
	return [visibleChildren count];
}

- (NSArray *)visibleChildren {
	return [[visibleChildren copy] autorelease];
}


- (MDNode *)visibleChildAtIndex:(NSUInteger)index {
	return [visibleChildren objectAtIndex:index];
}



// -------------------------------------------------------------------------------
//	Returns YES if self is contained anywhere inside the children or children of
//	sub-nodes of the nodes contained inside the given array.
// -------------------------------------------------------------------------------
- (BOOL)isContainedInNodes:(NSArray *)nodes {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// returns YES if we are contained anywhere inside the array passed in, including inside sub-nodes
	
	for (MDNode *node in nodes) {
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
}

// -------------------------------------------------------------------------------
//	Returns YES if any node in the array passed in is an ancestor of ours.
// -------------------------------------------------------------------------------
- (BOOL)isDescendantOfNodes:(NSArray *)nodes {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	for (MDNode *node in nodes) {
		// check all the sub-nodes
		if (![node isLeaf]) {
			if ([self isContainedInNodes:[node children]]) {
				return YES;
			}
		}
	}
	return NO;
}



- (BOOL)isDescendantOfNodeOrIsEqualToNode:(MDNode *)node {
#if MD_DEBUG
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

- (BOOL)isDescendantOfNode:(MDNode *)node {
#if MD_DEBUG
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
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	showInvisibleItems = value;
	if (!isLeaf && children) {
		for (MDNode *child in children) {
			if (![child isLeaf]) [child setShowInvisibleItems:showInvisibleItems];
		}
	}
}


- (void)setSortDescriptors:(NSArray *)aSortDescriptors {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self setSortDescriptors:aSortDescriptors recursively:YES];
}


- (void)setSortDescriptors:(NSArray *)aSortDescriptors recursively:(BOOL)recursively {
#if MD_DEBUG
	NSLog(@"[%@ %@] aSortDescriptors == %@, recursively == %@; sortDescriptors == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aSortDescriptors, recursively ? @"YES" : @"NO", sortDescriptors);
#endif
	
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (!isLeaf) {
		[aSortDescriptors retain];
		[sortDescriptors release];
		sortDescriptors = aSortDescriptors;
		
		if (children && recursively) {
			[children makeObjectsPerformSelector:@selector(setSortDescriptors:) withObject:sortDescriptors];
		}
	}
}


- (void)recursiveSortChildren {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	if (!isLeaf) {
		if (children) {
#if MD_DEBUG
//		NSLog(@"[%@ %@] children (before) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), children);
#endif
			
			[children sortUsingDescriptors:sortDescriptors];
			[visibleChildren sortUsingDescriptors:sortDescriptors];
			
#if MD_DEBUG
//			NSLog(@"[%@ %@] children (after) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), children);
#endif
			
			[children makeObjectsPerformSelector:@selector(recursiveSortChildren)];
		}
	}
}


@end



