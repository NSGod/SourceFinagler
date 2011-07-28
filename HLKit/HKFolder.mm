//
//  HKFolder.mm
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFolder.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKFoundationAdditions.h>
#import <HL/HL.h>

#import "HKPrivateInterfaces.h"

using namespace HLLib;

#define HK_DEBUG 0

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
		const hlChar *cName = static_cast<const CDirectoryFolder *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
		nameExtension = [[name pathExtension] retain];
		kind = [NSLocalizedString(@"Folder", @"") retain];
		isLeaf = NO;
		isExtractable = YES;
		isVisible = YES;
		size = [[NSNumber numberWithLongLong:-1] retain];
		countOfVisibleChildren = NSNotFound;
		fileType = HKFileTypeOther;
		[self setShowInvisibleItems:showInvisibles];
		
	}
	return self;
}



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
	
	NSString *targetName = nil;
	NSString *remainingPath = nil;
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
	
	targetName = [revisedPathComponents objectAtIndex:0];
	if (count > 1) remainingPath = [NSString pathWithComponents:[revisedPathComponents subarrayWithRange:NSMakeRange(1, (count - 1))]];
	
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
	return nil;
}


- (NSArray *)descendants {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray  *descendants = [[NSMutableArray alloc] init];
	
	for (HKItem *node in children) {
		[descendants addObject:node];
		
		if (![node isLeaf]) {
			[descendants addObjectsFromArray:[node descendants]];   // Recursive - will go down the chain to get all
		}
	}
	return [descendants autorelease];
}


- (NSArray *)visibleDescendants {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray *visibleDescendants = [[NSMutableArray alloc] init];
	
	for (HKItem *node in visibleChildren) {
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
	NSMutableDictionary *visibleDescendantsAndPaths = [NSMutableDictionary dictionary];
	
	NSArray *visibleDecendants = [self visibleDescendants];
	
	for (HKItem *item in visibleDecendants) {
		NSString *itemPath = [item pathRelativeToItem:parentItem];
		if (itemPath) {
			[visibleDescendantsAndPaths setObject:item forKey:itemPath];
		}
	}
	
	return visibleDescendantsAndPaths;
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


