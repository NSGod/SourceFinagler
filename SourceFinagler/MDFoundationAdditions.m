//
//  MDFoundationAdditions.m
//  MDFoundationAdditions
//
//  Created by Mark Douma on 12/03/2007.
//  Copyright (c) 2007-2011 Mark Douma LLC. All rights reserved.
//

#import "MDFoundationAdditions.h"
#import <sys/syslimits.h>
#import <openssl/sha.h>

#define MD_DEBUG 0



BOOL MDMouseInRects(NSPoint inPoint, NSArray *inRects, BOOL isFlipped) {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSEnumerator *enumerator = [inRects objectEnumerator];
	NSValue *rect;
	
	while ((rect = [enumerator nextObject])) {
		if (NSMouseInRect(inPoint, [rect rectValue], isFlipped)) {
			return YES;
		}
	}
	return NO;
}


static SInt32 MDSystemVersion = MDUnknownVersion;


SInt32 MDGetSystemVersion() {
	if (MDSystemVersion == MDUnknownVersion) {
		SInt32 fullVersion = 0;
		Gestalt(gestaltSystemVersion, &fullVersion);
		MDSystemVersion = fullVersion & 0xfffffff0;
	}
	return MDSystemVersion;
}
	
	

//@implementation NSURL (MDAdditions)
//
//- (BOOL)getFSRef:(FSRef *)anFSRef {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSString *filePath = [self path];
//	return [filePath getFSRef:anFSRef];
//}
//
//@end



@implementation NSString (MDAdditions)

#if (TARGET_CPU_PPC || TARGET_CPU_X86) && MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4

+ (NSString *)stringWithFSSpec:(const FSSpec *)anFSSpec {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	OSStatus status = noErr;
	FSRef fileRef;
	
	status = FSpMakeFSRef(anFSSpec, &fileRef);
	
	if (status == noErr) {
		return [self stringWithFSRef:&fileRef];
	} else {
		return nil;
	}
}
#endif


+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	UInt8 thePath[PATH_MAX + 1];
	
	OSStatus status = FSRefMakePath(anFSRef, thePath, PATH_MAX);
	
	if (status == noErr) {
		return [NSString stringWithUTF8String:(const char *)thePath];
	} else {
		return nil;
	}
}



- (BOOL)getFSRef:(FSRef *)anFSRef error:(NSError **)anError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (anError) *anError = nil;
	OSStatus status = noErr;
	status = FSPathMakeRef((const UInt8 *)[self UTF8String], anFSRef, NULL);
	if (status != noErr) {
		if (anError) *anError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
	}
	return (status == noErr);
}


- (BOOL)boolValue {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL value = NO;
	if (self) {
		if ([self isEqualToString:@"YES"] || [self isEqualToString:@"yes"]) {
			value = YES;
		} else if ([self isEqualToString:@"NO"] || [self isEqualToString:@"no"]) {
			value = NO;
}
	} else {
		value = NO;
	}
	return value;
}


/* TODO: I need to make sure that this method doesn't exceed the max 255 character filename limit	(NAME_MAX) */

- (NSString *)stringByAssuringUniqueFilename {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir;
	
	if ([fileManager fileExistsAtPath:self isDirectory:&isDir]) {
		NSString *basePath = [self stringByDeletingLastPathComponent];
		NSString *filename = [self lastPathComponent];
		NSString *filenameExtension = [filename pathExtension];
		NSString *basename = [filename stringByDeletingPathExtension];
		
		NSArray *components = [basename componentsSeparatedByString:@"-"];
		
		if ([components count] > 1) {
			// baseName contains at least one "-", determine if it's already a "duplicate". If it is, repeat the process of adding 1 to the value until the resulting filename would be unique. If it isn't, fall through to where we just tack on our own at the end of the filename
			NSString *basenameSuffix = [components lastObject];
			NSInteger suffixNumber = [basenameSuffix integerValue];
			if (suffixNumber > 0) {
				NSUInteger basenameSuffixLength = [basenameSuffix length];
			
				NSString *basenameSubstring = [basename substringWithRange:NSMakeRange(0, [basename length] - (basenameSuffixLength + 1))];
				while (1) {
					suffixNumber += 1;
					
					NSString *targetPath;
					
					if ([filenameExtension isEqualToString:@""]) {
						targetPath = [basePath stringByAppendingPathComponent:[basenameSubstring stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]]];
					} else {
						targetPath = [basePath stringByAppendingPathComponent:[[basenameSubstring stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]] stringByAppendingPathExtension:filenameExtension]];
					}
					
					if (![fileManager fileExistsAtPath:targetPath isDirectory:&isDir]) {
						return targetPath;
					}
				}
			}
		}
		
		// filename doesn't contain an (applicable) "-", so we just tack our own onto the end
		
		NSInteger suffixNumber = 0;
		
		while (1) {
			suffixNumber += 1;
			NSString *targetPath;
			if ([filenameExtension isEqualToString:@""]) {
				targetPath = [basePath stringByAppendingPathComponent:[basename stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]]];
			} else {
				targetPath = [basePath stringByAppendingPathComponent:[[basename stringByAppendingString:[NSString stringWithFormat:@"-%ld", (long)suffixNumber]] stringByAppendingPathExtension:filenameExtension]];				
			}
			if (![fileManager fileExistsAtPath:targetPath isDirectory:&isDir]) {
				return targetPath;
			}
		}
	}
	return self;
}


- (NSString *)stringByAbbreviatingFilenameTo31Characters {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *newFullPath = nil;
	NSString *filename = [self lastPathComponent];
	NSString *originalFilename = [[filename copy] autorelease];
	
	if ([filename length] > 30) {
		NSRange nilRange = NSMakeRange(NSNotFound, 0);
		NSRange pRange = [filename rangeOfString:@"("];
		
		if (NSEqualRanges(nilRange, pRange)) {
			NSArray *components = [filename componentsSeparatedByString:@" "];
			
			if ([components count] == 1) {
				NSString *prefix = [filename substringToIndex:29];
				NSString *lastCharacter = [filename substringFromIndex:[filename length] - 1];
				
				filename = [NSString stringWithFormat:@"%@%C%@", prefix, (unsigned short)0x2026, lastCharacter];				
				
			} else if ([components count] > 1) {
				NSUInteger lastComponentLength = [[components lastObject] length];
				
				NSString *suffix = [filename substringFromIndex:[filename length] - lastComponentLength - 1];
				suffix = [[NSString stringWithFormat:@"%C", (unsigned short)0x2026] stringByAppendingString:suffix];
				
				NSString *prefix = [filename substringToIndex:[filename length] - lastComponentLength - 2];
				
				NSUInteger allowedPrefixLength = (31 - [suffix length]);
				
				prefix = [prefix substringToIndex:allowedPrefixLength];
				filename = [prefix stringByAppendingString:suffix];
				
			}
			
		} else {
			
			NSString *suffix = [filename substringFromIndex:(pRange.location - 1)];
			NSString *prefix = [filename substringToIndex:(pRange.location - 1)];
			
			suffix = [[NSString stringWithFormat:@"%C", (unsigned short)0x2026] stringByAppendingString:suffix];
			
			NSUInteger allowedPrefixLength = (31 - [suffix length]);
			
			prefix = [prefix substringToIndex:allowedPrefixLength];
			
			filename = [prefix stringByAppendingString:suffix];
			
		}
		
		if (![originalFilename isEqualToString:filename]) {
			newFullPath = [[self stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
			
		} else {
			newFullPath = self;
		}
	} else {
		newFullPath = self;
	}
	return newFullPath;
}


- (NSSize)sizeForStringWithSavedFrame {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSSize size = NSZeroSize;
	
	NSArray *boundsArray = [self componentsSeparatedByString:@" "];
	
	if ([boundsArray count] != 4) {
//		NSLog(@"count of bounds array != 4, returning NSZeroSize...");
	} else {
		size.width = [[boundsArray objectAtIndex:2] floatValue];
		size.height = [[boundsArray objectAtIndex:3] floatValue];
	}

	return size;
}


+ (NSString *)stringWithPascalString:(ConstStr255Param )aPStr {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [(NSString *)CFStringCreateWithPascalString(kCFAllocatorDefault, aPStr, kCFStringEncodingMacRoman) autorelease];
}



//- (BOOL)getFSSpec:(FSSpec *)anFSSpec {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	FSRef anFSRef;
//	return [self getFSRef:&anFSRef] && (FSGetCatalogInfo( &anFSRef, kFSCatInfoNone, NULL, NULL, anFSSpec, NULL ) == noErr);
//}


- (BOOL)pascalString:(StringPtr)aBuffer length:(SInt16)aLength {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return CFStringGetPascalString((CFStringRef)self, aBuffer, aLength, kCFStringEncodingMacRoman);
}

- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options: NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch];
}

- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options:NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch range:NSMakeRange(0, [string length]) locale:[NSLocale currentLocale]];
}


- (BOOL)containsString:(NSString *)aString {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return (!NSEqualRanges([self rangeOfString:aString], NSMakeRange(NSNotFound, 0)));
}

- (NSString *)stringByReplacing:(NSString *)value with:(NSString *)newValue {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableString *newString = [NSMutableString stringWithString:self];
    [newString replaceOccurrencesOfString:value withString:newValue options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
    return newString;
}


- (NSString *)slashToColon {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self stringByReplacing:@"/" with:@":"];
}

- (NSString *)colonToSlash {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self stringByReplacing:@":" with:@"/"];
}


- (NSString *)displayPath {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *displayPath = nil;
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	NSArray *pathComponents = [fileManager componentsToDisplayForPath:self];
	if (pathComponents && [pathComponents count]) {
		if (displayPath == nil) {
			displayPath = @"/";
		}
		for (NSString *pathComponent in pathComponents) {
			displayPath = [displayPath stringByAppendingPathComponent:pathComponent];
		}
	}
	
	[fileManager release];
	
	return displayPath;
}


- (NSData *)bookmarkDataWithOptions:(MDBookmarkCreationOptions)options error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSData *bookmarkData = nil;
	if (outError) *outError = nil;
	NSString *path = [[self stringByResolvingSymlinksInPath] stringByStandardizingPath];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if ([fileManager fileExistsAtPath:path]) {
		AliasHandle alias = NULL;
		OSErr err = noErr;
		FSRef itemRef;
		if ([path getFSRef:&itemRef error:outError]) {
			if (options & MDBookmarkCreationDefaultOptions) {
				err = FSNewAlias(NULL, &itemRef, &alias);
				if (err == noErr) {
					HLock((Handle)alias);
					bookmarkData = [[[NSData dataWithBytes:*alias length:GetHandleSize((Handle)alias)] retain] autorelease];
					HUnlock((Handle)alias);
					if (alias) DisposeHandle((Handle)alias);
					
				} else {
					NSLog(@"[%@ %@] FSNewAlias() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
					if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
				}
			}
		}
	} else {
		NSLog(@"[%@ %@] no file exists at %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path);
		if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:fnfErr userInfo:nil];
	}
	[fileManager release];
	return bookmarkData;
}


+ (id)stringByResolvingBookmarkData:(NSData *)bookmarkData options:(MDBookmarkResolutionOptions)options bookmarkDataIsStale:(BOOL *)isStale error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSString *resolvedPath = nil;
	if (outError) *outError = nil;
	if (bookmarkData) {
		AliasHandle alias = NULL;
		FSRef resolvedRef;
		Boolean wasChanged = false;
		OSErr err = noErr;
		err = PtrToHand([bookmarkData bytes], (Handle *)&alias, [bookmarkData length]);
		if (err == noErr) {
			err = FSResolveAliasWithMountFlags(NULL, alias, &resolvedRef, &wasChanged, (options & MDBookmarkResolutionWithoutUI ? kResolveAliasFileNoUI : 0));
			if (err == noErr) {
				resolvedPath = [NSString stringWithFSRef:&resolvedRef];
				if (isStale) *isStale = wasChanged;
			} else {
				NSLog(@"[%@ %@] FSResolveAliasWithMountFlags() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
				if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
			}
		} else {
			NSLog(@"[%@ %@] PtrToHand() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
			if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		}
	}
	return resolvedPath;
}


@end


@implementation NSUserDefaults (MDSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sortDescriptors];
	if (data) [self setObject:data forKey:key];
}


- (NSArray *)sortDescriptorsForKey:(NSString *)key {
	return [NSKeyedUnarchiver unarchiveObjectWithData:[self objectForKey:key]];
}


@end

@implementation NSDictionary (MDSortDescriptorAdditions)

- (NSArray *)sortDescriptorsForKey:(NSString *)key {
	return [NSKeyedUnarchiver unarchiveObjectWithData:[self objectForKey:key]];
}

@end

@implementation NSMutableDictionary (MDSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sortDescriptors];
	if (data) [self setObject:data forKey:key];
}

@end


@implementation NSData (MDDescriptionAdditions)


- (NSString *)stringRepresentation {
	const char *bytes = [self bytes];
	NSUInteger stringLength = [self length];
	NSUInteger currentIndex;
	
	NSMutableString *stringRepresentation = [NSMutableString string];
	
	for (currentIndex = 0; currentIndex < stringLength; currentIndex++) {
		[stringRepresentation appendFormat:@"%02x", (unsigned char)bytes[currentIndex]];
	}
	return [[stringRepresentation copy] autorelease];
}

// prints raw hex + ascii
- (NSString *)enhancedDescription {
	
	NSMutableString *string = [NSMutableString string];   // full string result
	NSMutableString *hrStr = [NSMutableString string]; // "human readable" string
	
	NSInteger i, len;
	const unsigned char *b;
	len = [self length];
	b = [self bytes];
	
	if (len == 0) {
		return @"<empty>";
	}
	[string appendString:@"\n   "];
	
	NSInteger linelen = 16;
	for (i = 0; i < len; i++) {
		[string appendFormat:@" %02x", b[i]];
		if (isprint(b[i])) {
			[hrStr appendFormat:@"%c", b[i]];
		} else {
			[hrStr appendString:@"."];
		}
		if ((i % linelen) == (linelen - 1)) { // new line every linelen bytes
			[string appendFormat:@"    %@\n", hrStr];
			hrStr = [NSMutableString string];
			
			if (i < (len - 1)) {
				[string appendString:@"   "];
			}
		}
	}
	
	// make sure to print out the remaining hrStr part, aligned of course
	if ((len % linelen) != 0) {
		int bytesRemain = linelen - (len % linelen); // un-printed bytes
		for (i = 0; i < bytesRemain; i++) {
			[string appendString:@"   "];
		}
		[string appendFormat:@"    %@\n", hrStr];
	}
	return string;
}


@end



//#if 0
//
//@implementation NSData (MDAdditions)
//
//
//
//- (NSString *)sha1HexHash {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	unsigned char digest[SHA_DIGEST_LENGTH];
//	char hashString[(2 * SHA_DIGEST_LENGTH) + 1];
//	
//	SHA1([self bytes], [self length], digest);
//	
//	NSInteger currentIndex = 0;
//	
//	for (currentIndex = 0; currentIndex < SHA_DIGEST_LENGTH; currentIndex++) {
//		sprintf(hashString+currentIndex*2, "%02x", digest[currentIndex]);
//	}
//	hashString[currentIndex * 2] = 0;
//	
//	return [NSString stringWithUTF8String:(const char *)hashString];
//}
//
//
//- (NSData *)sha1Hash {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	unsigned char digest[SHA_DIGEST_LENGTH];
//	SHA1([self bytes], [self length], digest);
//	return [NSData dataWithBytes:&digest length:SHA_DIGEST_LENGTH];
//}
//
//
//@end
//
//
//@implementation NSBundle (MDAdditions)
//
//
//- (NSString *)checksumForAuxiliaryLibrary:(NSString *)dylibName {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSString *checksum = nil;
//	NSString *executablePath = [self executablePath];
//	if (executablePath && dylibName) {
//		NSString *dylibPath = [[executablePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:dylibName];
//		
//		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
//		BOOL isDir;
//		
//		if ([fileManager fileExistsAtPath:dylibPath isDirectory:&isDir] && !isDir) {
//			NSError *error = nil;
//			
//			NSData *dylibData = [NSData dataWithContentsOfFile:dylibPath options:NSDataReadingUncached error:&error];
//			if (dylibData) {
//				checksum = [dylibData sha1HexHash];
//			} else {
//				NSLog(@"[%@ %@] [NSData dataWithContentsOfFile:options:error:] returned nil with error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
//			}
//		}
//	}
//	return checksum;
//}
//
//@end
//
//#endif
//
//
//
//NSString *NSStringForAppleScriptListFromPaths(NSArray *paths) {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
//	
//	NSString *listString = @"{";
//	NSString *filePath;
//	NSInteger currentIndex;
//	NSInteger totalCount = [paths count];
//	
//	for (currentIndex = 0; currentIndex < totalCount; currentIndex++) {
//		filePath = [paths objectAtIndex:currentIndex];
//		listString = [listString stringByAppendingString:[NSString stringWithFormat:@"\"%@\" as POSIX file", filePath]];
//		
//		if (currentIndex < (totalCount - 1)) {
//			listString = [listString stringByAppendingString:@", "];
//		}
//	}
//	listString = [[listString stringByAppendingString:@"}"] retain];
//	
//	[localPool release];
//	
//	return [listString autorelease];
//}
//

//@implementation NSArray (MDAdditions)
//
//- (BOOL)containsObjectIdenticalTo:(id)obj { 
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//    return [self indexOfObjectIdenticalTo: obj] != NSNotFound; 
//}
//
//@end
//
//
//


@implementation NSMutableArray (MDAdditions)

- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [array count])]];
}


@end



////////////////////////////////////////////////////////////////
////    NSMutableDictionary CATEGORY FOR THREAD-SAFETY
////////////////////////////////////////////////////////////////



//@implementation NSMutableDictionary (MDThreadSafety)
//
//- (id)threadSafeObjectForKey:(id)aKey usingLock:(NSLock *)aLock {
//    id    result;
//	
//    [aLock lock];
//    result = [[[self objectForKey:aKey] retain] autorelease];
//    [aLock unlock];
//	
//    return result;
//}
//
//
//- (void)threadSafeRemoveObjectForKey:(id)aKey usingLock:(NSLock *)aLock {
//    [aLock lock];
//    [self removeObjectForKey:aKey];
//    [aLock unlock];
//}
//
//
//- (void)threadSafeSetObject:(id)anObject forKey:(id)aKey usingLock:(NSLock *)aLock {
//    [aLock lock];
//    [[anObject retain] autorelease];
//    [self setObject:anObject  forKey:aKey];
//    [aLock unlock];
//}
//
//
//@end



@implementation NSObject (MDDeepMutableCopy)

- (id)deepMutableCopy {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    if ([self respondsToSelector:@selector(mutableCopyWithZone:)]) {
        return [self mutableCopy];
	} else if ([self respondsToSelector:@selector(copyWithZone:)]) {
        return [self copy];
	} else {
        return [self retain];
	}
}

@end

@implementation NSDictionary (MDDeepMutableCopy)

- (id)deepMutableCopy {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
	id key = nil;
	
	NSArray *allKeys = [self allKeys];
	
	for (key in allKeys) {
		id copiedObject = [[self objectForKey:key] deepMutableCopy];
		
		id keyCopy = nil;
		
		if ([key conformsToProtocol:@protocol(NSCopying)]) {
			keyCopy = [key copy];
		} else {
			keyCopy = [key retain];
		}
		
		[newDictionary setObject:copiedObject forKey:keyCopy];
		[copiedObject release];
		[keyCopy release];
	}	
    return newDictionary;
}

@end


@implementation NSArray (MDDeepMutableCopy)

- (id)deepMutableCopy {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
	
	for (id object in self) {
		id copiedObject = [object deepMutableCopy];
		[newArray addObject:copiedObject];
		[copiedObject release];
	}
    return newArray;
}
	
@end



@implementation NSSet (MDDeepMutableCopy)

- (id)deepMutableCopy {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    NSMutableSet *newSet = [[NSMutableSet alloc] init];
	
	NSArray *allObjects = [self allObjects];
	
	for (id object in allObjects) {
		id copiedObject = [object deepMutableCopy];
		[newSet addObject:copiedObject];
		[copiedObject release];
	}
    return newSet;
}
	
@end


