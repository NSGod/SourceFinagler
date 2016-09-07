//
//  HKFolder.mm
//  HLKit
//
//  Created by Mark Douma on 9/1/2010.
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


#import <HLKit/HKFolder.h>
#import <HLKit/HKFile.h>
#import "HKFoundationAdditions.h"
#import <HL/HL.h>

#import "HKPrivateInterfaces.h"


using namespace HLLib;

#define HK_DEBUG 0



@interface HKFolder (HKPrivate)
- (void)populateChildrenIfNeeded;
@end


@implementation HKFolder


- (id)initWithParent:(HKFolder *)aParent directoryFolder:(const CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithParent:aParent childNodes:nil sortDescriptors:aSortDescriptors container:aContainer])) {
		_privateData = (void *)aFolder;
		isLeaf = NO;
		isExtractable = YES;
		isVisible = YES;
		countOfVisibleChildNodes = NSNotFound;
		[self setShowInvisibleItems:showInvisibles];
	}
	return self;
}


- (NSString *)name {
	if (name == nil) {
		const hlChar *cName = static_cast<const CDirectoryFile *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
	}
	return name;
}


- (NSString *)nameExtension {
	if (nameExtension == nil) nameExtension = [[[self name] pathExtension] retain];
	return nameExtension;
}


- (NSString *)kind {
	if (kind == nil) kind = [NSLocalizedString(@"Folder", @"") retain];
	return kind;
}


- (NSNumber *)size {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (size == nil) {
		unsigned long long totalSize = 0;
		
		NSArray *ourDescendants = self.descendants;
		
		for (HKItem *item in ourDescendants) {
			totalSize += [item.size unsignedLongLongValue];
		}
		size = [[NSNumber numberWithUnsignedLongLong:totalSize] retain];
	}
	return size;
}


- (HKFileType)fileType {
	if (fileType == HKFileTypeNone) fileType = HKFileTypeOther;
	return fileType;
}


- (NSUInteger)countOfChildNodes {
	return (NSUInteger)static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
}


- (NSUInteger)countOfVisibleChildNodes {
	if (countOfVisibleChildNodes == NSNotFound) {
		countOfVisibleChildNodes = 0;
		NSUInteger numChildren = static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
		for (NSUInteger i = 0; i < numChildren; i++) {
			CDirectoryItem *item = static_cast<CDirectoryFolder *>(_privateData)->GetItem(i);
			HLDirectoryItemType itemType = item->GetType();
			if (itemType == HL_ITEM_FOLDER) {
				countOfVisibleChildNodes++;
			} else if (itemType == HL_ITEM_FILE) {
				if (static_cast<const CDirectoryFile *>(item)->GetExtractable()) {
					countOfVisibleChildNodes++;
				}
			}
		}
	}
	return countOfVisibleChildNodes;
}


- (void)populateChildrenIfNeeded {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (childNodes == nil && visibleChildNodes == nil) {
		[self initializeChildrenIfNeeded];
		
		NSMutableArray *tempChildren = [[NSMutableArray alloc] init];
		
		hlUInt count = static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
		
		for (NSUInteger i = 0; i < count; i++) {
			const CDirectoryItem *item = static_cast<const CDirectoryFolder *>(_privateData)->GetItem(i);
			HLDirectoryItemType itemType = item->GetType();
			
			HKItem *child = nil;
			
			if (itemType == HL_ITEM_FOLDER) {
				child = [[HKFolder alloc] initWithParent:self directoryFolder:static_cast<const CDirectoryFolder *>(item) showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:container];
			} else if (itemType == HL_ITEM_FILE) {
				child = [[HKFile alloc] initWithParent:self directoryFile:static_cast<const CDirectoryFile *>(item) container:container];
			}
			if (child) {
				[tempChildren addObject:child];
				[child release];
			}
		}
		[self insertChildNodes:tempChildren atIndex:0];
		[tempChildren release];
	}
}


- (HKItem *)descendantAtPath:(NSString *)aPath {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aPath == nil) return nil;
	
	[self populateChildrenIfNeeded];
	
	NSArray *pathComponents = [aPath pathComponents];
	
	NSMutableArray *revisedPathComponents = [NSMutableArray array];
	
	for (NSString *component in pathComponents) {
		if (![component isEqualToString:@"/"]) [revisedPathComponents addObject:component];
	}
	
#if HK_DEBUG
	NSMutableString *description = [NSMutableString stringWithString:@""];
	[description appendFormat:@"path == %@\n", aPath];
	[description appendFormat:@"pathComponents == %@\n", pathComponents];
	[description appendFormat:@"revisedPathComponents == %@\n", revisedPathComponents];
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), description);
#endif
	
	NSUInteger count = [revisedPathComponents count];
	
	if (count == 0) return nil;
	
	NSString *targetName = [revisedPathComponents objectAtIndex:0];
	NSString *remainingPath = nil;
	
	if (count > 1) remainingPath = [NSString pathWithComponents:[revisedPathComponents subarrayWithRange:NSMakeRange(1, (count - 1))]];
	
	for (HKItem *child in childNodes) {
		if ([[child name] isEqualToString:targetName]) {
			if (remainingPath == nil) {
				return child;
			}
			// if there's remaining path left, and the child isn't a folder, then bail
			if ([child isLeaf]) return nil;
			
			return [(HKFolder *)child descendantAtPath:remainingPath];
		}
	}
	
	return nil;
}


- (NSArray *)descendants {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray  *descendants = [[NSMutableArray alloc] init];
	
	for (HKItem *node in childNodes) {
		[descendants addObject:node];
		
		if (![node isLeaf]) {
			[descendants addObjectsFromArray:[node descendants]];   // Recursive - will go down the chain to get all
		}
	}

	return [descendants autorelease];
}


- (NSArray *)visibleDescendants {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray *visibleDescendants = [[NSMutableArray alloc] init];
	
	for (HKItem *node in visibleChildNodes) {
		[visibleDescendants addObject:node];
		if (![node isLeaf]) {
			[visibleDescendants addObjectsFromArray:[node visibleDescendants]];	// Recursive - will go down the chain to get all
		}
	}
	
	return [visibleDescendants autorelease];
}


- (NSDictionary *)visibleDescendantsAndPathsRelativeToItem:(HKItem *)parentItem {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableDictionary *visibleDescendantsAndPaths = [[NSMutableDictionary alloc] init];
	
	NSArray *visibleDescendants = [self visibleDescendants];
	
	for (HKItem *item in visibleDescendants) {
		NSString *itemPath = [item pathRelativeToItem:parentItem];
		if (itemPath) {
			[visibleDescendantsAndPaths setObject:item forKey:itemPath];
		}
	}
	return [visibleDescendantsAndPaths autorelease];
}


- (HKNode *)childNodeAtIndex:(NSUInteger)index {
	[self populateChildrenIfNeeded];
	return [super childNodeAtIndex:index];
}

- (HKNode *)visibleChildNodeAtIndex:(NSUInteger)index {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [super visibleChildNodeAtIndex:index];
}

- (NSArray *)childNodes {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
    return [[childNodes copy] autorelease];
}


- (NSArray *)visibleChildNodes {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [[visibleChildNodes copy] autorelease];
}


- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if (![fileManager createDirectoryAtPath:aPath withIntermediateDirectories:YES attributes:nil error:outError]) {
		NSLog(@"[%@ %@] failed to create directory at %@!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
		[fileManager release];
		return NO;
	}
	[fileManager release];
	if (resultingPath) *resultingPath = aPath;
	return YES;
	
}




@end


