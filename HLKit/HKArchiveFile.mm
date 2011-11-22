//
//  HKArchiveFile.m
//  Source Finagler
//
//  Created by Mark Douma on 4/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKFolder.h>
#import <HL/HL.h>
#import "HKPrivateInterfaces.h"


using namespace HLLib;


#define HK_DEBUG 0


NSDate *startDate = nil;

#define HK_DEFAULT_PACKAGE_TEST_LENGTH 8

typedef struct HKArchiveFileTest {
	HKArchiveFileType	fileType;
	NSUInteger		testDataLength;
	unsigned char	testData[HK_DEFAULT_PACKAGE_TEST_LENGTH];
} HKArchiveFileTest;


static HKArchiveFileTest HKArchiveFileTestTable[] = {
	{ HKArchiveFileBSPType, 4, { 0x1e, 0x00, 0x00, 0x00 } },
	{ HKArchiveFileGCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 } },
	{ HKArchiveFileNCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00 } },
	{ HKArchiveFilePAKType, 4, { 'P', 'A', 'C', 'K' } },
	{ HKArchiveFileVBSPType, 4, { 'V', 'B', 'S', 'P' } },
	{ HKArchiveFileVPKType, 4, { 0x34, 0x12, 0xaa, 0x55} },
	{ HKArchiveFileWADType, 4, { 'W', 'A', 'D', '3' } },
	{ HKArchiveFileXZPType, 4, { 'p', 'i', 'Z', 'x' } },
	{ HKArchiveFileZIPType, 2, { 'P', 'K' } },
	{ HKArchiveFileNoType, 0, { } }
};


@implementation HKArchiveFile



@synthesize filePath, fileType, haveGatheredAllItems, isReadOnly, version;


+ (HKArchiveFileType)fileTypeForData:(NSData *)aData {
#if HK_DEBUG
	NSLog(@"[%@ %@] aData == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aData);
#endif
	NSUInteger dataLength = [aData length];
	if (dataLength == 0) {
		return HKArchiveFileNoType;
	}
	for (HKArchiveFileTest *packageTest = HKArchiveFileTestTable; packageTest->fileType != HKArchiveFileNoType; packageTest++) {
		if (packageTest->testDataLength <= dataLength && memcmp([aData bytes], packageTest->testData, packageTest->testDataLength) == 0) {
			return packageTest->fileType;
		}
	}
	return HKArchiveFileNoType;
}


- (id)initWithContentsOfFile:(NSString *)aPath {
	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE | HL_MODE_QUICK_FILEMAPPING showInvisibleItems:YES sortDescriptors:nil error:NULL];
}

- (id)initWithContentsOfFile:(NSString *)aPath showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors  error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE | HL_MODE_QUICK_FILEMAPPING showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError];
	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError];
}


- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if HK_DEBUG
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
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[filePath release];
	[items release];
	[allItems release];
	[version release];
	[super dealloc];
}



- (HKFolder *)items {
#if HK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return items;
}


- (HKItem *)itemAtPath:(NSString *)path {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self items] descendantAtPath:path];
}



- (NSArray *)allItems {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (!haveGatheredAllItems) {
		
		startDate = [[NSDate date] retain];
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSMutableArray *gatheredItems = [NSMutableArray array];
		
		[gatheredItems addObject:items];
		
		NSArray *children = [items children];
		
		for (HKItem *item in children) {
			
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

