//
//  MDFolderManager.m
//  Font Finagler
//
//  Created by Mark Douma on 11/16/2006.
//  Copyright © 2006-2011 Mark Douma. All rights reserved.
//


#import "MDFolderManager.h"
#import "MDFoundationAdditions.h"
#import <sys/syslimits.h>

#define MD_DEBUG 0

static MDFolderManager *sharedManager = nil;

@implementation MDFolderManager

+ (MDFolderManager *)defaultManager {
	if (sharedManager == nil) {
		sharedManager = [[super allocWithZone:NULL] init];
	}
	return sharedManager;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self defaultManager] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)init {
	if ((self = [super init])) {
		tempDirectories = nil;
	}
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return NSUIntegerMax; //denotes an object that cannot be released
}

- (oneway void)release {
	// do nothing
}

- (id)autorelease {
	return self;
}


+ (NSString *)tempDirectoryWithIdentifier:(NSString *)aName {
	return [[MDFolderManager defaultManager] tempDirectoryWithIdentifier:aName assureUniqueFilename:NO];
}


+ (NSString *)tempDirectoryWithIdentifier:(NSString *)aName assureUniqueFilename:(BOOL)flag {
	return [[MDFolderManager defaultManager] tempDirectoryWithIdentifier:aName assureUniqueFilename:flag];
}

+ (BOOL)cleanupTempDirectoryAtPath:(NSString *)aPath error:(NSError **)outError {
	return [[MDFolderManager defaultManager] cleanupTempDirectoryAtPath:aPath error:outError];
}


- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain error:(NSError **)outError {
	return [self pathForDirectory:aDirectory inDomain:aDomain create:NO error:outError];
}


- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain create:(BOOL)create error:(NSError **)outError {
	NSString *path = nil;
	OSErr err = noErr;
	FSRef folderRef;
	if (outError) *outError = nil;
	
	if ( (aDirectory == MDFontCollectionsDirectory) || (aDirectory == MDFontsDisabledDirectory) || (aDirectory == MDDarwinUserCachesDirectory) ) {
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		BOOL isDir;
		
		if (aDirectory == MDFontsDisabledDirectory) {
			err = FSFindFolder(aDomain, MDFontsDirectory, create, &folderRef);
			
			if (err == noErr) {
				path = [NSString stringWithFSRef:&folderRef];
				if (path) {
					NSString *folderName = [path lastPathComponent];
					
					path = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:[folderName stringByAppendingString:@" (Disabled)"]];
					
					if ([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) {
						
					} else if ([fileManager fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
						NSLog(@"[%@ %@] \"Fonts (Disabled)\" exists, but is a file, not a directory!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
						path = nil;
						
					} else {
						NSDictionary *attributes = nil;
						
						if (aDomain == MDLocalDomain) {
							attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0775],NSFilePosixPermissions, [NSNumber numberWithUnsignedLong:0],NSFileOwnerAccountID, [NSNumber numberWithUnsignedLong:80],NSFileGroupOwnerAccountID, nil];							
							
						} else {
							attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:getuid()],NSFileOwnerAccountID, [NSNumber numberWithUnsignedLong:getgid()],NSFileGroupOwnerAccountID, nil];
						}
						
						if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:attributes error:outError]) {
							NSLog(@"[%@ %@] failed to createDirectoryAtPath: %@ attributes: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path, attributes);
							
							attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:0775],NSFilePosixPermissions, nil];							
							
							if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:attributes error:outError]) {
								NSLog(@"[%@ %@] failed to createDirectoryAtPath: %@ attributes: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path, attributes);
							}
						}
					}
				}
			} else {
				if (err != fnfErr) {
					NSLog(@"[%@ %@] FSFindFolder() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
					if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
				}
			}
		} else if (aDirectory == MDFontCollectionsDirectory) {
			err = FSFindFolder(aDomain, MDFontCollectionsDirectory, create, &folderRef);
			
			if (err == noErr) {
				path = [NSString stringWithFSRef:&folderRef];
			} else {
				NSLog(@"[%@ %@] initial FSFindFolder() with MDFontCollectionsDirectory returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
				err = FSFindFolder(aDomain, MDLibraryDirectory, create, &folderRef);
				
				if (err == noErr) {
					path = [NSString stringWithFSRef:&folderRef];
					if (path) {
						path = [path stringByAppendingPathComponent:@"FontCollections"];
					}
					
					if ( !([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
						path = nil;
					}
				} else {
					if (err != fnfErr) {
						NSLog(@"[%@ %@] FSFindFolder() with MDLibraryDirectory returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
						if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
						
					}
				}
			}
		} else if (aDirectory == MDDarwinUserCachesDirectory) {
			char *buffer = malloc(PATH_MAX + 1);
			size_t size = 0;
			size = confstr(_CS_DARWIN_USER_CACHE_DIR, buffer, PATH_MAX + 1);
			if (size > 0 && buffer != NULL) {
				path = [NSString stringWithUTF8String:(const char *)buffer];
				if (path) {
					path = [path stringByStandardizingPath];
					if ( !([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir)) {
						path = nil;
					}
				}
			} else {
				NSLog(@"[%@ %@] size <= 0 || buffer == NULL", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				if (outError) *outError = [NSError errorWithDomain:NSPOSIXErrorDomain	code:errno userInfo:nil];
			}
			if (buffer) free(buffer);
		}
		
	} else {
		err = FSFindFolder(aDomain, aDirectory, create, &folderRef);
		if (err == noErr) {
			path = [NSString stringWithFSRef:&folderRef];
		} else if (err != fnfErr) {
			NSLog(@"[%@ %@] FSFindFolder() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
			if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		}
	}
	return path;
}



- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory forItemAtPath:(NSString *)aPath error:(NSError **)outError {
	return [self pathForDirectory:aDirectory forItemAtPath:aPath create:NO error:outError];
}

- (NSString *)pathForDirectory:(MDSearchPathDirectory)aDirectory forItemAtPath:(NSString *)aPath create:(BOOL)create error:(NSError **)outError {
	NSString *path = nil;
	OSErr err = noErr;
	FSRef aPathRef;
	if (outError) *outError = nil;
	FSCatalogInfo catInfo;
	if ([aPath getFSRef:&aPathRef error:outError]) {
		err = FSGetCatalogInfo(&aPathRef, kFSCatInfoVolume, &catInfo, NULL, NULL, NULL);
		if (err == noErr) {
			path = [self pathForDirectory:aDirectory inDomain:catInfo.volume create:create error:outError];
		}
	}
	return path;
}


- (NSString *)pathForDirectoryWithName:(NSString *)aName inDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain error:(NSError **)outError {
	return [self pathForDirectoryWithName:aName inDirectory:aDirectory inDomain:aDomain create:NO error:outError];
}


- (NSString *)pathForDirectoryWithName:(NSString *)aName inDirectory:(MDSearchPathDirectory)aDirectory inDomain:(MDSearchPathDomain)aDomain create:(BOOL)create error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *path = nil;
	if (outError) *outError = nil;
	
	if (aName) {
		NSString *parentDirectory = [self pathForDirectory:aDirectory inDomain:aDomain create:YES error:outError];
		if (parentDirectory) {
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			BOOL isDir;
			path = [parentDirectory stringByAppendingPathComponent:aName];
			if ( !([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir) && create) {
				if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:outError]) {
					path = nil;
				}
			}
			[fileManager release];
		}
	}
	return path;
}



- (NSString *)tempDirectoryWithIdentifier:(NSString *)aName {
	return [self tempDirectoryWithIdentifier:aName assureUniqueFilename:NO];
}


- (NSString *)tempDirectoryWithIdentifier:(NSString *)aName assureUniqueFilename:(BOOL)flag {
	NSString *tempDirectory = nil;
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
			BOOL isDir;
	NSError *outError = nil;

	if (aName == nil) aName = @"com.markdouma.folder";

	NSString *initialTempDirectory = [self pathForDirectory:MDTemporaryDirectory inDomain:MDAllDomains create:YES error:&outError];

	if (initialTempDirectory) {
		tempDirectory = [[initialTempDirectory stringByAppendingPathComponent:aName] stringByAppendingString:[NSString stringWithFormat:@".%u.noindex", getuid()]];
		
		if (flag) {
			tempDirectory = [tempDirectory stringByAssuringUniqueFilename];
				}
		
		if ( !([fileManager fileExistsAtPath:tempDirectory isDirectory:&isDir] && isDir) ) {
			if (![fileManager createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:NULL]) {
				NSLog(@"[%@ %@] failed to create tempDirectory at path %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tempDirectory);
				tempDirectory = nil;
			}
		}
		if (tempDirectory) {
			if (tempDirectories == nil) {
				tempDirectories = [[NSMutableArray alloc] init];
	}
			[tempDirectories addObject:tempDirectory];
}
	}
	return tempDirectory;
}

	
- (BOOL)cleanupTempDirectoryAtPath:(NSString *)aPath error:(NSError **)outError {
	BOOL success = YES;
	if (outError) {
		*outError = nil;
	}
	if (aPath && [tempDirectories containsObject:aPath]) {
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		BOOL isDir;
		
		if ([fileManager fileExistsAtPath:aPath isDirectory:&isDir] && isDir) {
			success = [fileManager removeItemAtPath:aPath error:outError];
		}
	}
	return success;
}


@end



