//
//  MDHLPrivateInterfaces.h
//  Source Finagler
//
//  Created by Mark Douma on 12/16/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HL/HL.h>

#import "MDFolder.h"
#import "MDFile.h"
#import "MDHLFile.h"

using namespace HLLib;

struct MDHLFilePackagePair {
	MDHLFileType	fileType;
	HLPackageType	packageType;
};

static const MDHLFilePackagePair MDHLFilePackagePairTable[] = {
	{ MDHLFileNoType, HL_PACKAGE_NONE },
	{ MDHLFileBSPType, HL_PACKAGE_BSP },
	{ MDHLFileGCFType, HL_PACKAGE_GCF },
	{ MDHLFilePAKType, HL_PACKAGE_PAK },
	{ MDHLFileVBSPType, HL_PACKAGE_VBSP },
	{ MDHLFileWADType, HL_PACKAGE_WAD },
	{ MDHLFileXZPType, HL_PACKAGE_XZP },
	{ MDHLFileZIPType, HL_PACKAGE_ZIP },
	{ MDHLFileNCFType, HL_PACKAGE_NCF },
	{ MDHLFileVPKType, HL_PACKAGE_VPK }
};
static const NSUInteger MDHLFilePackagePairTableCount = sizeof(MDHLFilePackagePairTable);

static inline HLPackageType MDHLPackageTypeFromHLFileType(MDHLFileType aFileType) {
	for (NSUInteger i = 0; i < MDHLFilePackagePairTableCount; i++) {
		if (aFileType == MDHLFilePackagePairTable[i].fileType) {
			return MDHLFilePackagePairTable[i].packageType;
		}
	}
	return HL_PACKAGE_NONE;
}


@interface MDFolder (MDHLPrivateInterfaces)

- (id)initWithParent:(MDFolder *)aParent directoryFolder:(const CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@end


@interface MDFile (MDHLPrivateInterfaces)

- (id)initWithParent:(MDFolder *)aParent directoryFile:(const CDirectoryFile *)aFile container:(id)aContainer;

@end

@interface MDHLFile (MDHLPrivateInterfaces)

- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError;

@end
