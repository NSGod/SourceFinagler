//
//  HKNode.h
//  HLKit
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright (c) 2009-2011 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HKNode : NSObject {
	id					container;	// not retained
	
	HKNode				*parent;	// not retained

    NSMutableArray		*children;
	NSMutableArray		*visibleChildren;
	
	NSArray				*sortDescriptors;
	
	BOOL				isLeaf;
	
	BOOL				isVisible;
	BOOL				showInvisibleItems;
	
}
- (id)initWithParent:(HKNode *)aParent children:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@property (nonatomic, assign) id container;
@property (nonatomic, assign) HKNode *parent;
@property (nonatomic, assign, setter=setVisible:) BOOL isVisible;
@property (nonatomic, assign) BOOL showInvisibleItems;
@property (nonatomic, assign, setter=setLeaf:) BOOL isLeaf;

@property (nonatomic, retain) NSArray *sortDescriptors;

@property (nonatomic, assign, readonly) BOOL isRootNode;


- (void)insertChild:(HKNode *)child atIndex:(NSUInteger)index;
- (void)insertChildren:(NSArray *)newChildren atIndex:(NSUInteger)index;
- (void)removeChild:(HKNode *)child;
- (void)removeFromParent;

- (NSUInteger)indexOfChild:(HKNode *)child;
- (NSUInteger)indexOfChildIdenticalTo:(HKNode *)child;

- (NSUInteger)countOfChildren;
- (NSArray *)children;
- (HKNode *)childAtIndex:(NSUInteger)index;

- (NSUInteger)countOfVisibleChildren;
- (NSArray *)visibleChildren;
- (HKNode *)visibleChildAtIndex:(NSUInteger)index;


- (BOOL)isContainedInNodes:(NSArray *)nodes;
- (BOOL)isDescendantOfNodes:(NSArray *)nodes;

- (BOOL)isDescendantOfNode:(HKNode *)node;

- (void)setSortDescriptors:(NSArray *)aSortDescriptors recursively:(BOOL)recursively;

- (void)recursiveSortChildren;

- (void)initializeChildrenIfNeeded;

@end

