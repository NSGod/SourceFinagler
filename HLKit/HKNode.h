//
//  HKNode.h
//  HLKit
//
//  Created by Mark Douma on 9/2/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HKNode : NSObject {
	id					container;	// not retained
	
	HKNode				*parent;	// not retained

    NSMutableArray		*childNodes;
	NSMutableArray		*visibleChildNodes;
	
	NSArray				*sortDescriptors;
	
	BOOL				isLeaf;
	
	BOOL				isVisible;
	BOOL				showInvisibleItems;
	
}
- (id)initWithParent:(HKNode *)aParent childNodes:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@property (nonatomic, assign) id container;
@property (nonatomic, assign) HKNode *parent;
@property (nonatomic, assign, setter=setVisible:) BOOL isVisible;
@property (nonatomic, assign) BOOL showInvisibleItems;
@property (nonatomic, assign, setter=setLeaf:) BOOL isLeaf;

@property (nonatomic, retain) NSArray *sortDescriptors;

@property (nonatomic, assign, readonly) BOOL isRootNode;


- (void)insertChildNode:(HKNode *)child atIndex:(NSUInteger)index;
- (void)insertChildNodes:(NSArray *)newChildren atIndex:(NSUInteger)index;
- (void)removeChildNode:(HKNode *)child;
- (void)removeFromParent;

- (NSUInteger)indexOfChildNode:(HKNode *)child;
- (NSUInteger)indexOfChildNodeIdenticalTo:(HKNode *)child;

- (NSUInteger)countOfChildNodes;
- (NSArray *)childNodes;
- (HKNode *)childNodeAtIndex:(NSUInteger)index;

- (NSUInteger)countOfVisibleChildNodes;
- (NSArray *)visibleChildNodes;
- (HKNode *)visibleChildNodeAtIndex:(NSUInteger)index;


- (BOOL)isContainedInNodes:(NSArray *)nodes;
- (BOOL)isDescendantOfNodes:(NSArray *)nodes;

- (BOOL)isDescendantOfNode:(HKNode *)node;

- (void)setSortDescriptors:(NSArray *)aSortDescriptors recursively:(BOOL)recursively;

- (void)recursiveSortChildren;

- (void)initializeChildrenIfNeeded;

@end

