//
//  HKFolder.mm
//  HLKit
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFolder.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKFoundationAdditions.h>
#import <HL/HL.h>

#import "HKPrivateInterfaces.h"

using namespace HLLib;

#define HK_DEBUG 0

#define HK_LAZY_INIT 1

#define HK_USE_BLOCKS 0

#if HK_USE_BLOCKS
#else
#endif



@interface HKFolder (Private)
- (void)populateChildrenIfNeeded;
@end


@implementation HKFolder


- (id)initWithParent:(HKFolder *)aParent directoryFolder:(CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithParent:aParent children:nil sortDescriptors:aSortDescriptors container:aContainer])) {
		_privateData = aFolder;
		isLeaf = NO;
		isExtractable = YES;
		isVisible = YES;
		size = [[NSNumber numberWithLongLong:-1] retain];
		countOfVisibleChildren = NSNotFound;
		[self setShowInvisibleItems:showInvisibles];
		
#if !(HK_LAZY_INIT)
		const hlChar *cName = static_cast<const CDirectoryFolder *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
		nameExtension = [[name pathExtension] retain];
		kind = [NSLocalizedString(@"Folder", @"") retain];
		fileType = HKFileTypeOther;
#endif
	}
	return self;
}

#if (HK_LAZY_INIT)

- (NSString *)name {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (name == nil) {
		const hlChar *cName = static_cast<const CDirectoryFile *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
	}
	return name;
}

- (NSString *)nameExtension {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (nameExtension == nil) nameExtension = [[[self name] pathExtension] retain];
	return nameExtension;
}

//- (NSString *)type {
//#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	if (type == nil) {
//		type = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[self nameExtension], NULL);
//	}
//	return type;
//}

- (NSString *)kind {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (kind == nil) kind = [NSLocalizedString(@"Folder", @"") retain];
	return kind;
}


- (HKFileType)fileType {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (fileType == HKFileTypeNone) fileType = HKFileTypeOther;
	return fileType;
}

#endif


- (NSUInteger)countOfChildren {
	return (NSUInteger)static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
}

- (NSUInteger)countOfVisibleChildren {
	if (countOfVisibleChildren == NSNotFound) {
		countOfVisibleChildren = 0;
		NSUInteger numChildren = static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
		for (NSUInteger i = 0; i < numChildren; i++) {
			CDirectoryItem *item = static_cast<CDirectoryFolder *>(_privateData)->GetItem(i);
			HLDirectoryItemType itemType = item->GetType();
			if (itemType == HL_ITEM_FOLDER) {
				countOfVisibleChildren++;
			} else if (itemType == HL_ITEM_FILE) {
				if (static_cast<const CDirectoryFile *>(item)->GetExtractable()) {
					countOfVisibleChildren++;
				}
			}
		}
	}
	return countOfVisibleChildren;
}

- (void)populateChildrenIfNeeded {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (children == nil && visibleChildren == nil) {
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
		[self insertChildren:tempChildren atIndex:0];
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
	
#if HK_USE_BLOCKS
	__block HKItem *descendant = nil;
	
	[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKItem *child, NSUInteger idx, BOOL *stop) {
		if ([[child name] isEqualToString:targetName]) {
			if (remainingPath == nil) {
				descendant = child;
				if (stop) *stop = YES;
			}
			// if there's remaining path left, and the child isn't a folder, then bail
			if ([child isLeaf]) {
				if (stop) *stop = YES;
			}
			
			descendant = [(HKFolder *)child descendantAtPath:remainingPath];
		}
	}];
	
	return descendant;
	
#else
	for (HKItem *child in children) {
		if ([[child name] isEqualToString:targetName]) {
			if (remainingPath == nil) {
				return child;
			}
			// if there's remaining path left, and the child isn't a folder, then bail
			if ([child isLeaf]) return nil;
			
			return [(HKFolder *)child descendantAtPath:remainingPath];
		}
	}
#endif
	return nil;
}


- (NSArray *)descendants {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray  *descendants = [[NSMutableArray alloc] init];
	
//#if HK_USE_BLOCKS
//	[children enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKItem *node, NSUInteger idx, BOOL *stop) {
//		if (node) {
//			[descendants addObject:node];
//			if (![node isLeaf]) [descendants addObjectsFromArray:[node descendants]];
//		}
//	}];
//#else
	for (HKItem *node in children) {
		[descendants addObject:node];
		
		if (![node isLeaf]) {
			[descendants addObjectsFromArray:[node descendants]];   // Recursive - will go down the chain to get all
		}
	}
//#endif
	return [descendants autorelease];
}


- (NSArray *)visibleDescendants {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray *visibleDescendants = [[NSMutableArray alloc] init];
	
//#if HK_USE_BLOCKS
//	
//#if HK_DEBUG
////	NSLog(@"[%@ %@] path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self path]);
//#endif
//	
//	[visibleChildren enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKItem *visibleChild, NSUInteger idx, BOOL *stop) {
//#if HK_DEBUG
////		NSLog(@"[%@ %@] path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [self path]);
//#endif
//		if (visibleChild) {
//			[visibleDescendants addObject:visibleChild];
//			if (![visibleChild isLeaf]) [visibleDescendants addObjectsFromArray:[visibleChild visibleDescendants]]; // Recursive - will go down the chain to get all
//		}
//	}];
//#else
	for (HKItem *node in visibleChildren) {
		[visibleDescendants addObject:node];
		if (![node isLeaf]) {
			[visibleDescendants addObjectsFromArray:[node visibleDescendants]];	// Recursive - will go down the chain to get all
		}
	}
//#endif
	return [visibleDescendants autorelease];
}


- (NSDictionary *)visibleDescendantsAndPathsRelativeToItem:(HKItem *)parentItem {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableDictionary *visibleDescendantsAndPaths = [[NSMutableDictionary alloc] init];
	
	NSArray *visibleDescendants = [self visibleDescendants];
	
//#if HK_USE_BLOCKS
//	[visibleDescendants enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(HKItem *item, NSUInteger idx, BOOL *stop) {
//		if (item) {
//			NSString *itemPath = [item pathRelativeToItem:parentItem];
//			if (itemPath) [visibleDescendantsAndPaths setObject:item forKey:itemPath];
//		}
//	}];
//#else
	for (HKItem *item in visibleDescendants) {
		NSString *itemPath = [item pathRelativeToItem:parentItem];
		if (itemPath) {
			[visibleDescendantsAndPaths setObject:item forKey:itemPath];
		}
	}
//#endif
	return [visibleDescendantsAndPaths autorelease];
}


- (HKNode *)childAtIndex:(NSUInteger)index {
	[self populateChildrenIfNeeded];
	return [super childAtIndex:index];
}

- (HKNode *)visibleChildAtIndex:(NSUInteger)index {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [super visibleChildAtIndex:index];
}

- (NSArray *)children {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
    return [[children copy] autorelease];
}


- (NSArray *)visibleChildren {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [[visibleChildren copy] autorelease];
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


