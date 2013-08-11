//
//  HKPrivateInterfaces.h
//  HLKit
//
//  Created by Mark Douma on 12/16/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <HL/HL.h>

#import <HLKit/HLKitDefines.h>
#import <HLKit/HKFolder.h>
#import <HLKit/HKFile.h>
#import <HLKit/HKArchiveFile.h>


using namespace HLLib;

struct HKArchiveFilePackagePair {
	HKArchiveFileType	fileType;
	HLPackageType		packageType;
};

static const HKArchiveFilePackagePair HKArchiveFilePackagePairTable[] = {
	{ HKArchiveFileNoType, HL_PACKAGE_NONE },
	{ HKArchiveFileBSPType, HL_PACKAGE_BSP },
	{ HKArchiveFileGCFType, HL_PACKAGE_GCF },
	{ HKArchiveFilePAKType, HL_PACKAGE_PAK },
	{ HKArchiveFileVBSPType, HL_PACKAGE_VBSP },
	{ HKArchiveFileWADType, HL_PACKAGE_WAD },
	{ HKArchiveFileXZPType, HL_PACKAGE_XZP },
	{ HKArchiveFileZIPType, HL_PACKAGE_ZIP },
	{ HKArchiveFileNCFType, HL_PACKAGE_NCF },
	{ HKArchiveFileVPKType, HL_PACKAGE_VPK },
	{ HKArchiveFileVPKType, HL_PACKAGE_SGA }
};
static const NSUInteger HKArchiveFilePackagePairTableCount = sizeof(HKArchiveFilePackagePairTable);

static inline HLPackageType HLPackageTypeFromHKArchiveFileType(HKArchiveFileType aFileType) {
	for (NSUInteger i = 0; i < HKArchiveFilePackagePairTableCount; i++) {
		if (aFileType == HKArchiveFilePackagePairTable[i].fileType) {
			return HKArchiveFilePackagePairTable[i].packageType;
		}
	}
	return HL_PACKAGE_NONE;
}




@interface HKFolder (HKPrivateInterfaces)

- (id)initWithParent:(HKFolder *)aParent directoryFolder:(const CDirectoryFolder *)aFolder showInvisibleItems:(BOOL)showInvisibles sortDescriptors:(NSArray *)aSortDescriptors container:(id)aContainer;

@end


@interface HKFile (HKPrivateInterfaces)

- (id)initWithParent:(HKFolder *)aParent directoryFile:(const CDirectoryFile *)aFile container:(id)aContainer;

@end

@interface HKArchiveFile (HKPrivateInterfaces)

- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError;

@end
