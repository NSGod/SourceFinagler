/*
    MDItem.m
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


#import "MDItem.h"
#import "MDFoundationAdditions.h"
#import "MDHLFile.h"

#define MD_DEBUG 0

NSString * const MDHLErrorDomain			= @"MDHLErrorDomain";
NSString * const MDHLErrorMessageKey		= @"MDHLErrorMessage";
NSString * const MDHLSystemErrorMessageKey	= @"MDHLSystemErrorMessage";


@implementation MDItem

@synthesize name, nameExtension, kind, size,
		type, isExtractable, isEncrypted,
		fileType, dimensions, version, compression,
		hasAlpha, hasMipmaps;

@dynamic path;

- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	return [self initWithParent:nil children:nil sortDescriptors:nil container:nil];
}


- (id)initWithParent:(MDNode *)aParent children:(NSArray *)theChildren sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
	if ((self = [super initWithParent:aParent children:theChildren sortDescriptors:aSortDescriptors container:aContainer])) {
		fileType = MDFileTypeNone;
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[name release];
	[nameExtension release];
	[kind release];
	[size release];
	[path release];
	[type release];
	[dimensions release];
	[version release];
	[compression release];
	[hasAlpha release];
	[hasMipmaps release];
	[super dealloc];
}


- (NSString *)path {
	if (path) return path;
	if (parent && ![parent isRootNode]) {
		NSString *parentsPath = [(MDItem *)parent path];
		[self setPath:[parentsPath stringByAppendingPathComponent:name]];
		return path;
	}
	
	if (container) {
		[self setPath:[@"/" stringByAppendingPathComponent:name]];
		return path;
	}
	return nil;
}


- (void)setPath:(NSString *)aPath {
	NSString *copy = [aPath copy];
	[path release];
	path = copy;
}


- (NSString *)pathRelativeToItem:(MDItem *)referenceItem {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (parent == referenceItem) return name;
	
	NSString *relativePath = nil;
	
	MDItem *theItem = self;
	
	while ((theItem = (MDItem *)[theItem parent])) {
		if (theItem == referenceItem) {
			// **
			if (relativePath == nil) relativePath = name;
			break;
		}
		NSString *itemName = [theItem name];
		//**
		if (relativePath == nil) relativePath = name;
		
		if (itemName) relativePath = [itemName stringByAppendingPathComponent:relativePath];
	}
	return relativePath;
}


- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@] subclasses must implement!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return NO;
}


// -------------------------------------------------------------------------------
//	Override this for any non-object values
// -------------------------------------------------------------------------------
- (void)setNilValueForKey:(NSString *)key {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"isExtractable"]) {
		isExtractable = NO;
	} else if ([key isEqualToString:@"isEncrypted"]) {
		isEncrypted = NO;
	} else if ([key isEqualToString:@"fileType"]) {
		fileType = MDFileTypeNone;
	} else {
		[super setNilValueForKey:key];
	}
}


// -------------------------------------------------------------------------------
//	Generates an array of all descendants.
// -------------------------------------------------------------------------------
- (NSArray *)descendants {
#if MD_DEBUG
	NSLog(@"[%@ %@] subclasses must override!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return nil;
}

- (NSArray *)visibleDescendants {
#if MD_DEBUG
	NSLog(@"[%@ %@] subclasses must override!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return nil;
}

static NSString * const MDFileTypeDescription[] = {
						@"MDFileTypeNone",
						@"MDFileTypeHTML",
						@"MDFileTypeText",
						@"MDFileTypeImage",
						@"MDFileTypeSound",
						@"MDFileTypeMovie",
						@"MDFileTypeOther",
						@"MDFileTypeNotExtractable"
};

- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:@"{\n"];
//	[description appendFormat:@"%@\n\t", [super description]];
	[description appendFormat:@"\tname == %@\n", name];
	[description appendFormat:@"\tpath == %@\n", [self path]];
	if (!isLeaf) [description appendFormat:@"\tshowInvisibleItems == %@\n", (showInvisibleItems ? @"YES" : @"NO")];
	if (!isLeaf) [description appendFormat:@"\tsortDescriptors == %@\n", sortDescriptors];
	[description appendFormat:@"}\n"];
//	[description appendFormat:@"\n\tnameExtension == %@", nameExtension];
//	[description appendFormat:@"\n\tkind == %@", kind];
//	[description appendFormat:@"\n\tsize == %@", size];
//	[description appendFormat:@"\n\ttype == %@", type];
//	[description appendFormat:@"\n\fileType == %@", MDFileTypeDescription[fileType]];
//	[description appendFormat:@"\n\tisVisible == %@", (isVisible ? @"YES" : @"NO")];
	
	return description;
}


@end



// -------------------------------------------------------------------------------
//	Finds the receiver's parent from the nodes contained in the array.
// -------------------------------------------------------------------------------
//- (id)parentFromArray:(NSArray *)array {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	id result = nil;
//	for (MDItem *node in array) {
//		if (node == self) {     // If we are in the root array, return nil
//			break;
//		}
//		if ([[node children] containsObjectIdenticalTo:self]) {
//			result = node;
//			break;
//		}
//		if (![node isLeaf]) {
//			MDItem *innerNode = [self parentFromArray:[node children]];
//			if (innerNode) {
//				result = innerNode;
//				break;
//			}
//		}
//	}
//
//	return result;
//}



// -------------------------------------------------------------------------------
//	Returns the index path of within the given array,
//	useful for drag and drop.
// -------------------------------------------------------------------------------
//- (NSIndexPath *)indexPathInArray:(NSArray *)array {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSIndexPath	*indexPath = nil;
//	NSMutableArray  *reverseIndexes = [NSMutableArray array];
//	id aParent, doc = self;
//	NSInteger index;
//
//	while (aParent = [doc parentFromArray:array]) {
//		index = [[aParent children] indexOfObjectIdenticalTo:doc];
//		if (index == NSNotFound) {
//			return nil;
//		}
//		[reverseIndexes addObject:[NSNumber numberWithInteger:index]];
//		doc = aParent;
//	}
//
//	// If parent is nil, we should just be in the parent array
//	index = [array indexOfObjectIdenticalTo:doc];
//	if (index == NSNotFound) {
//		return nil;
//	}
//	[reverseIndexes addObject:[NSNumber numberWithInteger:index]];
//
//	// Now build the index path
//	NSEnumerator *re = [reverseIndexes reverseObjectEnumerator];
//	NSNumber *indexNumber;
//	while (indexNumber = [re nextObject]) {
//		if (indexPath == nil) {
//			indexPath = [NSIndexPath indexPathWithIndex:[indexNumber integerValue]];
//		} else {
//			indexPath = [indexPath indexPathByAddingIndex:[indexNumber integerValue]];
//		}
//	}
//
//	return indexPath;
//}

