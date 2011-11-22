//
//  MDNode.h
//  Source Finagler
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MDNode : NSObject {
	id					container;	// not retained
	
	MDNode				*parent;	// not retained

    NSMutableArray		*children;
	NSMutableArray		*visibleChildren;
	
	NSArray				*sortDescriptors;
	
	BOOL				isLeaf;
	
	BOOL				isVisible;
	BOOL				showInvisibleItems;
	
}
- (id)initWithParent:(MDNode *)aParent children:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@property (assign) id container;
@property (assign) MDNode *parent;
@property (assign, setter=setVisible:) BOOL isVisible;
@property (assign) BOOL showInvisibleItems;
@property (assign, setter=setLeaf:) BOOL isLeaf;

@property (nonatomic, retain) NSArray *sortDescriptors;

@property (assign, readonly) BOOL isRootNode;


- (void)insertChild:(MDNode *)child atIndex:(NSUInteger)index;
- (void)insertChildren:(NSArray *)newChildren atIndex:(NSUInteger)index;
- (void)removeChild:(MDNode *)child;
- (void)removeFromParent;

- (NSUInteger)indexOfChild:(MDNode *)child;
- (NSUInteger)indexOfChildIdenticalTo:(MDNode *)child;

- (NSUInteger)countOfChildren;
- (NSArray *)children;
- (MDNode *)childAtIndex:(NSUInteger)index;

- (NSUInteger)countOfVisibleChildren;
- (NSArray *)visibleChildren;
- (MDNode *)visibleChildAtIndex:(NSUInteger)index;


- (BOOL)isContainedInNodes:(NSArray *)nodes;
- (BOOL)isDescendantOfNodes:(NSArray *)nodes;

- (BOOL)isDescendantOfNode:(MDNode *)node;

- (void)setSortDescriptors:(NSArray *)aSortDescriptors recursively:(BOOL)recursively;

- (void)recursiveSortChildren;

- (void)initializeChildrenIfNeeded;

@end

