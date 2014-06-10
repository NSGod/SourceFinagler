//
//  HKVPKFile.mm
//  HLKit
//
//  Created by Mark Douma on 10/27/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import "HKVPKFile.h"
#import <HLKit/HKFile.h>
#import <HLKit/HKFileAdditions.h>
#import <HLKit/HKFolder.h>
#import "HKPrivateInterfaces.h"
#import <HL/HL.h>


static NSString * const HKSourceAddonInfoNameKey					= @"addoninfo.txt";
static NSString * const HKSourceAddonSteamAppIDKey					= @"addonSteamAppID";


using namespace HLLib;


#define HK_DEBUG 0



@implementation HKVPKFile

@synthesize archiveVersion;
@synthesize archiveCount;

@synthesize archiveDirectoryFilePath;

@synthesize vpkArchiveType;
@synthesize sourceAddonStatus;

@synthesize sourceAddonGameID;


- (id)initWithContentsOfFile:(NSString *)aPath mode:(HLFileMode)permission showInvisibleItems:(BOOL)showInvisibleItems sortDescriptors:(NSArray *)sortDescriptors error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithContentsOfFile:aPath mode:permission showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors error:outError])) {
		archiveFileType = HKArchiveFileVPKType;
		
		_privateData = new CVPKFile();
		
		if (_privateData) {
			if (static_cast<CVPKFile *>(_privateData)->Open((const hlChar *)[filePath fileSystemRepresentation], permission)) {
				const CDirectoryFolder *rootFolder = static_cast<CVPKFile *>(_privateData)->GetRoot();
				if (rootFolder) {
					items = [[HKFolder alloc] initWithParent:nil directoryFolder:rootFolder showInvisibleItems:showInvisibleItems sortDescriptors:sortDescriptors container:self];
					
					HLAttribute archiveVersionAttr;
					HLAttribute archiveCountAttr;
					
					if (static_cast<CVPKFile *>(_privateData)->GetAttribute(HL_VPK_PACKAGE_Version, archiveVersionAttr)) {
						archiveVersion = (NSUInteger)archiveVersionAttr.Value.UnsignedInteger.uiValue;
						version = [[NSString stringWithFormat:@"%lu", (unsigned long)archiveVersion] retain];
					}
					
					if (static_cast<CVPKFile *>(_privateData)->GetAttribute(HL_VPK_PACKAGE_Archives, archiveCountAttr)) {
						archiveCount = (NSUInteger)archiveCountAttr.Value.UnsignedInteger.uiValue;
					}
				}
			}
		}
		
		NSString *fileName = [filePath lastPathComponent];
		NSString *baseName = [fileName stringByDeletingPathExtension];
		
		if ([baseName hasSuffix:@"_dir"]) {
			
			vpkArchiveType = HKVPKDirectoryArchiveType;
			archiveDirectoryFilePath = [filePath retain];
			sourceAddonStatus = HKSourceAddonNotAnAddonFile;
			
		} else {
			
			if (baseName.length >= 4) {
				NSString *last4String = [baseName substringFromIndex:baseName.length - 4];
				
				if ([last4String hasPrefix:@"_"]) {
					NSString *last3String = [last4String substringFromIndex:1];
					
					static NSCharacterSet *numCharSet = nil;
					if (numCharSet == nil) numCharSet = [[NSCharacterSet decimalDigitCharacterSet] retain];
					
					last3String = [last3String stringByTrimmingCharactersInSet:numCharSet];
					
					if (last3String.length == 0) {
						vpkArchiveType = HKVPKMultipartArchiveType;
						sourceAddonStatus = HKSourceAddonNotAnAddonFile;
						
						NSString *targetFileName = [[[baseName substringToIndex:baseName.length - 4] stringByAppendingString:@"_dir"] stringByAppendingPathExtension:@"vpk"];
						
						NSString *targetDirFilePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:targetFileName];
						
						BOOL isDir;
						
						if ([[NSFileManager defaultManager] fileExistsAtPath:targetDirFilePath isDirectory:&isDir] && !isDir) {
							archiveDirectoryFilePath = [targetDirFilePath retain];
						}
					}
				}
			}
			
			// if archive type is still unknown, try seeing if it's a Source Addon file
			
			if (vpkArchiveType == HKVPKUnknownArchiveType) {
				
				HKItem *addonInfoItem = [self itemAtPath:HKSourceAddonInfoNameKey];
				
#if HK_DEBUG
				NSLog(@"[%@ %@] addonInfoItem == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), addonInfoItem);
#endif
				
				if (addonInfoItem == nil || ![addonInfoItem isKindOfClass:[HKFile class]] || addonInfoItem.fileType != HKFileTypeText) {
					NSLog(@"[%@ %@] item at path (%@) does not appear to contain a valid addoninfo.txt file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), filePath);
					
					vpkArchiveType = HKVPKSourceAddonFileArchiveType;
					sourceAddonStatus = HKSourceAddonNoAddonInfoFound;
					
					return self;
				}
				
				
				NSString *stringValue = [(HKFile *)addonInfoItem stringValueByExtractingToTempFile:YES];
				if (stringValue == nil) stringValue = [(HKFile *)addonInfoItem stringValue];
				
				if (stringValue == nil) {
					NSLog(@"[%@ %@] could not determine string encoding of addoninfo.txt file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
					
					vpkArchiveType = HKVPKSourceAddonFileArchiveType;
					sourceAddonStatus = HKSourceAddonAddonInfoUnreadable;
					
					return self;
				}
				
#if HK_DEBUG
				NSLog(@"[%@ %@] stringValue == '%@'", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringValue);
#endif
				
				NSArray *words = [stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				NSMutableArray *revisedWords = [NSMutableArray array];
				
				for (NSString *word in words) {
					if (word.length) [revisedWords addObject:word];
				}
				
				NSUInteger count = [revisedWords count];
				NSUInteger keyIndex = [revisedWords indexOfObject:HKSourceAddonSteamAppIDKey];
				
				if (keyIndex == NSNotFound || !(keyIndex + 1 < count)) {
					NSLog(@"[%@ %@] failed to find '%@' key and/or value in addoninfo.txt in (%@)!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), HKSourceAddonSteamAppIDKey, filePath);
					NSLog(@"[%@ %@] stringValue == '%@'", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringValue);
					
					vpkArchiveType = HKVPKSourceAddonFileArchiveType;
					sourceAddonStatus = HKSourceAddonNoGameIDFoundInAddonInfo;
					
					return self;
				}
				
				NSString *addonSteamAppIDString = [revisedWords objectAtIndex:keyIndex + 1];
				
				// strip any quotes first
				
				addonSteamAppIDString = [addonSteamAppIDString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				
				
				sourceAddonGameID = [addonSteamAppIDString integerValue];
				
#if HK_DEBUG
				NSLog(@"[%@ %@] addonSteamAppIDString == %@, sourceAddonGameID == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), addonSteamAppIDString, (long)sourceAddonGameID);
#endif
				
				vpkArchiveType = HKVPKSourceAddonFileArchiveType;
				sourceAddonStatus = HKSourceAddonValidAddon;
				
			}
		}
	}
	return self;
}


- (void)dealloc {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[archiveDirectoryFilePath release];
	if (_privateData) {
		static_cast<CVPKFile *>(_privateData)->Close();
		delete static_cast<CVPKFile *>(_privateData);
	}
	[super dealloc];
}



- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"\n\n%@ -\n", [super description]];
	[description appendFormat:@"\tfilePath == %@\n", filePath];
	[description appendFormat:@"\tarchiveDirectoryFilePath == %@\n", archiveDirectoryFilePath];
	[description appendFormat:@"\tarchiveVersion == %lu\n", (unsigned long)archiveVersion];
	[description appendFormat:@"\tarchiveCount== %lu\n", (unsigned long)archiveCount];
	
	if (sourceAddonGameID) [description appendFormat:@"\tsourceAddonGameID == %lu\n\n", (unsigned long)sourceAddonGameID];
	return [NSString stringWithFormat:@"%@", description];
}


@end



