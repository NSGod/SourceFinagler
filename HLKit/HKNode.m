//
//  HKNode.m
//  HLKit
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

//  Based, in part, on "TreeNode":

/*
    TreeNode.m
    Copyright (c) 2001-2006, Apple Computer, Inc., all rights reserved.
    Author: Chuck Pisula

    Milestones:
    * 03-01-2001: Initial creation by Chuck Pisula
    * 02-17-2006: Cleaned up the code. Corbin Dunn.

    Generic Tree node structure (TreeNode).
    
    TreeNode is a node in a doubly linked tree data structure.  TreeNode's have weak references to their parent (to avoid retain 
    cycles since parents retain their children).  Each node has 0 or more children and a reference to a piece of node data. The TreeNode provides method to manipulate and extract structural information about a tree.  For instance, TreeNode implements: insertChild:atIndex:, removeChild:, isDescendantOfNode:, and other useful operations on tree nodes.
    TreeNode provides the structure and common functionality of trees and is expected to be subclassed.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import <HLKit/HKNode.h>
#import "HKFoundationAdditions.h"


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
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[theChildren makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	for (HKNode *child in theChildren) {
		[childNodes removeObjectIdenticalTo:child];
		[visibleChildNodes removeObjectIdenticalTo:child];
	}

}


- (void)removeChildNode:(HKNode *)child {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
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
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
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



