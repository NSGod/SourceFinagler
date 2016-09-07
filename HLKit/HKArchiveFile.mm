//
//  HKArchiveFile.m
//  HLKit
//
//  Created by Mark Douma on 4/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKArchiveFile.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKFolder.h>
#import <HL/HL.h>
#import "HKPrivateInterfaces.h"


using namespace HLLib;

#define HK_DEBUG 0

#define HK_DEFAULT_PACKAGE_TEST_LENGTH 8


typedef struct HKArchiveFileTest {
	HKArchiveFileType	archiveFileType;
	NSUInteger			testDataLength;
	unsigned char		testData[HK_DEFAULT_PACKAGE_TEST_LENGTH];
} HKArchiveFileTest;


static HKArchiveFileTest HKArchiveFileTestTable[] = {
	{ HKArchiveFileBSPType, 4, { 0x1e, 0x00, 0x00, 0x00 } },
	{ HKArchiveFileGCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00 } },
	{ HKArchiveFileNCFType, 8, { 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00 } },
	{ HKArchiveFilePAKType, 4, { 'P', 'A', 'C', 'K' } },
	{ HKArchiveFileSGAType, 8, { '_', 'A', 'R', 'C', 'H', 'I', 'V', 'E' } },
	{ HKArchiveFileVBSPType, 4, { 'V', 'B', 'S', 'P' } },
	{ HKArchiveFileVPKType, 4, { 0x34, 0x12, 0xaa, 0x55} },
	{ HKArchiveFileWADType, 4, { 'W', 'A', 'D', '3' } },
	{ HKArchiveFileXZPType, 4, { 'p', 'i', 'Z', 'x' } },
	{ HKArchiveFileZIPType, 2, { 'P', 'K' } },
	{ HKArchiveFileNoType, 0, { } }
};


@implementation HKArchiveFile


@synthesize filePath;
@synthesize fileSize;
@synthesize archiveFileType;
@synthesize haveGatheredAllItems;
@synthesize isReadOnly;
@synthesize version;



+ (HKArchiveFileType)archiveFileTypeForContentsOfFile:(NSString *)aPath {
#if HK_DEBUG
	NSLog(@"[%@ %@] aPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
#endif
	if ([[[aPath pathExtension] lowercaseString] isEqualToString:@"vpk"]) {
		return HKArchiveFileVPKType;
	}
	
	NSError *outError = nil;
	
	NSData *dataForMagic = [[[NSData alloc] initWithContentsOfFile:aPath options:NSDataReadingMapped | NSDataReadingUncached error:&outError] autorelease];
	if ([dataForMagic length] < HK_DEFAULT_PACKAGE_TEST_LENGTH) {
		NSLog(@" dataForMagic length < HK_DEFAULT_PACKAGE_TEST_LENGTH (8)! aPath == %@", aPath);
		return HKArchiveFileNoType;
	}
	NSData *magicData = [dataForMagic subdataWithRange:NSMakeRange(0, 8)];
	
	NSUInteger dataLength = [magicData length];
	
	for (HKArchiveFileTest *packageTest = HKArchiveFileTestTable; packageTest->archiveFileType != HKArchiveFileNoType; packageTest++) {
		if (packageTest->testDataLength <= dataLength && memcmp([magicData bytes], packageTest->testData, packageTest->testDataLength) == 0) {
			return packageTest->archiveFileType;
		}
	}
	return HKArchiveFileNoType;
}


- (id)initWithContentsOfFile:(NSString *)aPath {
//	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE | HL_MODE_QUICK_FILEMAPPING showInvisibleItems:YES sortDescriptors:nil error:NULL];
	return [self initWithContentsOfFile:aPath mode:HL_MODE_READ | HL_MODE_VOLATILE showInvisibleItems:YES sortDescriptors:nil error:NULL];
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
		fileSize = [[[[[[NSFileManager alloc] init] autorelease] attributesOfItemAtPath:filePath error:NULL] objectForKey:NSFileSize] retain];
		isReadOnly = !(permission & HL_MODE_WRITE);
	}
	return self;
}

- (void)dealloc {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[filePath release];
	[fileSize release];
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
	
	if (!haveGatheredAllItems) {
		
#if HK_DEBUG
		NSDate *startDate = [[NSDate date] retain];
#endif
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSMutableArray *gatheredItems = [[NSMutableArray alloc] init];
		
		[gatheredItems addObject:items];
		
		NSArray *childNodes = [items childNodes];
		
		for (HKItem *item in childNodes) {
			
			[gatheredItems addObject:item];
			
			if (![item isLeaf]) {
				[gatheredItems addObjectsFromArray:[item descendants]];
			}
		}
		allItems = gatheredItems;
		
		[pool release];
		
		haveGatheredAllItems = YES;
		
#if HK_DEBUG
		NSLog(@"[%@ %@] ****** TIME to gather allItems == %.7f sec, gatheredItems count == %lu, allItems count == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), fabs([startDate timeIntervalSinceNow]), (unsigned long)[gatheredItems count], (unsigned long)[allItems count]);
		[startDate release];
#endif
		
	}
	return allItems;
}
	

@end

