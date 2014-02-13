//
//  HKNode.h
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

