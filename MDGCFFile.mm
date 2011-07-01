//
//  MDGCFFile.mm
//  Source Finagler
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDGCFFile.h"
#import "MDFile.h"
#import "MDFolder.h"
#import "MDHLPrivateInterfaces.h"
#import <HL/HL.h>


@implementation MDGCFFile

@synthesize packageID, blockSize, totalBlockCount, usedBlockCount, freeBlockCount, lastVersionPlayed;


- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithContentsOfFile:aPath mode:permission showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError])) {
		fileType = MDHLFileGCFType;
		
		_privateData = new CGCFFile();
		
		if (_privateData) {
			if (static_cast<CGCFFile *>(_privateData)->Open((const hlChar *)[filePath fileSystemRepresentation], permission)) {
				const CDirectoryFolder *rootFolder = static_cast<CGCFFile *>(_privateData)->GetRoot();
				if (rootFolder) {
					items = [[MDFolder alloc] initWithParent:nil directoryFolder:rootFolder showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:self];
					
					HLAttribute versionAttr;
					HLAttribute packageIDAttr;
					HLAttribute blockSizeAttr;
					HLAttribute totalBlockCountAttr;
					HLAttribute usedBlockCountAttr;
					HLAttribute lastVersionPlayedAttr;
					
					
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_VERSION, versionAttr)) {
						version = [[NSString stringWithFormat:@"1.%lu", versionAttr.Value.UnsignedInteger.uiValue] retain];
					}
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_ID, packageIDAttr)) {
						packageID = (NSUInteger)packageIDAttr.Value.UnsignedInteger.uiValue;
					}
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_BLOCK_LENGTH, blockSizeAttr)) {
						blockSize = (NSUInteger)blockSizeAttr.Value.UnsignedInteger.uiValue;
					}
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_ALLOCATED_BLOCKS, totalBlockCountAttr)) {
						totalBlockCount = (NSUInteger)totalBlockCountAttr.Value.UnsignedInteger.uiValue;
					}
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_USED_BLOCKS, usedBlockCountAttr)) {
						usedBlockCount = (NSUInteger)usedBlockCountAttr.Value.UnsignedInteger.uiValue;
					}
					freeBlockCount = totalBlockCount - usedBlockCount;
					
					if (static_cast<CGCFFile *>(_privateData)->GetAttribute(HL_GCF_PACKAGE_LAST_VERSION_PLAYED, lastVersionPlayedAttr)) {
						lastVersionPlayed = (NSUInteger)lastVersionPlayedAttr.Value.UnsignedInteger.uiValue;
					}
				}
			}
		}
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (_privateData) {
		static_cast<CGCFFile *>(_privateData)->Close();
		delete static_cast<CGCFFile *>(_privateData);
	}
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:@""];
	[description appendFormat:@"\tfilePath == %@\n", filePath];
	[description appendFormat:@"\tpackageID == %lu\n", packageID];
	[description appendFormat:@"\tblockSize == %lu\n", blockSize];
	[description appendFormat:@"\ttotalBlockCount == %lu\n", totalBlockCount];
	[description appendFormat:@"\tusedBlockCount == %lu\n", usedBlockCount];
	[description appendFormat:@"\tlastVersionPlayed == %lu\n", lastVersionPlayed];
	return [NSString stringWithFormat:@"%@", description];
}



@end










