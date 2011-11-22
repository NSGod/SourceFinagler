//
//  MDHLFile.m
//  Source Finagler
//
//  Created by Mark Douma on 4/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDHLFile.h"
#import "MDFile.h"
#import "MDFolder.h"
#import <HL/HL.h>
#import "MDHLPrivateInterfaces.h"


using namespace HLLib;


#define MD_DEBUG 0


NSDate *startDate = nil;

#define MD_DEFAULT_PACKAGE_TEST_LENGTH 8

typedef struct MDHLFileTest {
	MDHLFileType	fileType;
	NSUInteger		testDataLength;
	unsigned char	testData[MD_DEFAULT_PACKAGE_TEST_LENGTH];
} MDHLFileTest;


static MDHLFileTest MDHLFileTestTable[] = {
	{ MDHLFileBSPType, 4, { 0x1e, 0x00, 0x00, 0x00 } },
	{ MDHLFileGCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 } },
	{ MDHLFileNCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00 } },
	{ MDHLFilePAKType, 4, { 'P', 'A', 'C', 'K' } },
	{ MDHLFileVBSPType, 4, { 'V', 'B', 'S', 'P' } },
	{ MDHLFileVPKType, 4, { 0x34, 0x12, 0xaa, 0x55} },
	{ MDHLFileWADType, 4, { 'W', 'A', 'D', '3' } },
	{ MDHLFileXZPType, 4, { 'p', 'i', 'Z', 'x' } },
	{ MDHLFileZIPType, 2, { 'P', 'K' } },
	{ MDHLFileNoType, 0, { } }
};


@implementation MDHLFile



@synthesize filePath, fileType, haveGatheredAllItems, isReadOnly, version;


+ (MDHLFileType)fileTypeForData:(NSData *)aData {
#if MD_DEBUG
	NSLog(@"[%@ %@] aData == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aData);
#endif
	NSUInteger dataLength = [aData length];
	if (dataLength == 0) {
		return MDHLFileNoType;
	}
	for (MDHLFileTest *packageTest = MDHLFileTestTable; packageTest->fileType != MDHLFileNoType; packageTest++) {
		if (packageTest->testDataLength <= dataLength && memcmp([aData bytes], packageTest->testData, packageTest->testDataLength) == 0) {
			return packageTest->fileType;
		}
	}
	return MDHLFileNoType;
}


- (id)initWithContentsOfFile:(NSString *)aPath {
	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE | HL_MODE_QUICK_FILEMAPPING showInvisibleItems:YES sortDescriptors:nil error:NULL];
}

- (id)initWithContentsOfFile:(NSString *)aPath showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors  error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE | HL_MODE_QUICK_FILEMAPPING showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError];
	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError];
}


- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (aPath == nil) {
		NSLog(@"[%@ %@] path == nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[self release];
		return nil;
	}
	
	if ((self = [super init])) {
		filePath = [aPath retain];
		_privateData = 0;
		haveGatheredAllItems = NO;
		isReadOnly = !(permission & HL_MODE_WRITE);
	}
	return self;
}

- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[filePath release];
	[items release];
	[allItems release];
	[version release];
	[super dealloc];
}



- (MDFolder *)items {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return items;
}


- (MDItem *)itemAtPath:(NSString *)path {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self items] descendantAtPath:path];
}



- (NSArray *)allItems {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (!haveGatheredAllItems) {
		
		startDate = [[NSDate date] retain];
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSMutableArray *gatheredItems = [NSMutableArray array];
		
		[gatheredItems addObject:items];
		
		NSArray *children = [items children];
		
		for (MDItem *item in children) {
			
			[gatheredItems addObject:item];
			
			if (![item isLeaf]) {
				[gatheredItems addObjectsFromArray:[item descendants]];
			}
		}
		allItems = [gatheredItems copy];
		
		[pool release];
		
		haveGatheredAllItems = YES;
		
		NSLog(@"[%@ %@] ****** TIME to gather allItems == %.7f sec, gatheredItems count == %lu, allItems count == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fabs([startDate timeIntervalSinceNow]), (unsigned long)[gatheredItems count], (unsigned long)[allItems count]);
		
		[startDate release];
		startDate = nil;
	}
	return allItems;
}
	

@end

