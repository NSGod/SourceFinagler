//
//  MDFolder.mm
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDFolder.h"
#import "MDFile.h"
#import "MDFoundationAdditions.h"
#import <HL/HL.h>

#import "MDHLPrivateInterfaces.h"

using namespace HLLib;

#define MD_DEBUG 0

@interface MDFolder (Private)
- (void)populateChildrenIfNeeded;
@end



@implementation MDFolder


- (id)initWithParent:(MDFolder *)aParent directoryFolder:(CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer {
#if MD_DEBUG
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
		fileType = MDFileTypeOther;
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
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (children == nil && visibleChildren == nil) {
		[self initializeChildrenIfNeeded];
		
		NSMutableArray *tempChildren = [[NSMutableArray alloc] init];
		
		hlUInt count = static_cast<const CDirectoryFolder *>(_privateData)->GetCount();
		
		for (NSUInteger i = 0; i < count; i++) {
			const CDirectoryItem *item = static_cast<const CDirectoryFolder *>(_privateData)->GetItem(i);
			HLDirectoryItemType itemType = item->GetType();
			
			MDItem *child = nil;
			
			if (itemType == HL_ITEM_FOLDER) {
				child = [[MDFolder alloc] initWithParent:self directoryFolder:static_cast<const CDirectoryFolder *>(item) showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:container];
			} else if (itemType == HL_ITEM_FILE) {
				child = [[MDFile alloc] initWithParent:self directoryFile:static_cast<const CDirectoryFile *>(item) container:container];
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


- (MDItem *)descendantAtPath:(NSString *)aPath {
#if MD_DEBUG
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
	
#if MD_DEBUG
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
	
	for (MDItem *child in children) {
		if ([[child name] isEqualToString:targetName]) {
			if (remainingPath == nil) {
				return child;
			}
			// if there's remaining path left, and the child isn't a folder, then bail
			if ([child isLeaf]) return nil;
			
			return [(MDFolder *)child descendantAtPath:remainingPath];
		}
	}
	return nil;
}


- (NSArray *)descendants {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray  *descendants = [[NSMutableArray alloc] init];
	
	for (MDItem *node in children) {
		[descendants addObject:node];
		
		if (![node isLeaf]) {
			[descendants addObjectsFromArray:[node descendants]];   // Recursive - will go down the chain to get all
		}
	}
	return [descendants autorelease];
}


- (NSArray *)visibleDescendants {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	
	NSMutableArray *visibleDescendants = [[NSMutableArray alloc] init];
	
	for (MDItem *node in visibleChildren) {
		[visibleDescendants addObject:node];
		if (![node isLeaf]) {
			[visibleDescendants addObjectsFromArray:[node visibleDescendants]];	// Recursive - will go down the chain to get all
		}
	}
	return [visibleDescendants autorelease];
}


- (NSDictionary *)visibleDescendantsAndPathsRelativeToItem:(MDItem *)parentItem {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableDictionary *visibleDescendantsAndPaths = [NSMutableDictionary dictionary];
	
	NSArray *visibleDecendants = [self visibleDescendants];
	
	for (MDItem *item in visibleDecendants) {
		NSString *itemPath = [item pathRelativeToItem:parentItem];
		if (itemPath) {
			[visibleDescendantsAndPaths setObject:item forKey:itemPath];
		}
	}
	
	return visibleDescendantsAndPaths;
}


- (MDNode *)childAtIndex:(NSUInteger)index {
	[self populateChildrenIfNeeded];
	return [super childAtIndex:index];
}

- (MDNode *)visibleChildAtIndex:(NSUInteger)index {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [super visibleChildAtIndex:index];
}

- (NSArray *)children {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
    return [[children copy] autorelease];
}


- (NSArray *)visibleChildren {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self populateChildrenIfNeeded];
	return [[visibleChildren copy] autorelease];
}


- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename tag:(NSInteger)tag  resultingPath:(NSString **)resultingPath error:(NSError **)outError {
#if MD_DEBUG
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


