//
//  TKFoundationAdditions.m
//  TKFoundationAdditions
//
//  Created by Mark Douma on 12/03/2007.
//  Copyright (c) 2007-2011 Mark Douma LLC. All rights reserved.
//

#import "TKFoundationAdditions.h"
#import <sys/syslimits.h>
#import <openssl/sha.h>

#define TK_DEBUG 0


static SInt32 TKSystemVersion = TKUnknownVersion;


SInt32 TKGetSystemVersion() {
	if (TKSystemVersion == TKUnknownVersion) {
		SInt32 fullVersion = 0;
		Gestalt(gestaltSystemVersion, &fullVersion);
		TKSystemVersion = fullVersion & 0xfffffff0;
	}
	return TKSystemVersion;
}
	
	


@implementation NSString (TKAdditions)


+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef {
#if TK_DEBUG
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
#if TK_DEBUG
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


/* TODO: I need to make sure that this method doesn't exceed the max 255 character filename limit	(NAME_MAX) */

- (NSString *)stringByAssuringUniqueFilename {
#if TK_DEBUG
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


+ (NSString *)stringWithPascalString:(ConstStr255Param )aPStr {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [(NSString *)CFStringCreateWithPascalString(kCFAllocatorDefault, aPStr, kCFStringEncodingMacRoman) autorelease];
}


- (BOOL)pascalString:(StringPtr)aBuffer length:(SInt16)aLength {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return CFStringGetPascalString((CFStringRef)self, aBuffer, aLength, kCFStringEncodingMacRoman);
}

- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options: NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch];
}

- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options:NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch range:NSMakeRange(0, [string length]) locale:[NSLocale currentLocale]];
}


- (NSString *)stringByReplacing:(NSString *)value with:(NSString *)newValue {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableString *newString = [NSMutableString stringWithString:self];
    [newString replaceOccurrencesOfString:value withString:newValue options:NSLiteralSearch range:NSMakeRange(0, [newString length])];
    return newString;
}


- (NSString *)slashToColon {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self stringByReplacing:@"/" with:@":"];
}

- (NSString *)colonToSlash {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self stringByReplacing:@":" with:@"/"];
}


- (NSString *)displayPath {
#if TK_DEBUG
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

@end



@implementation NSUserDefaults (TKSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sortDescriptors];
	if (data) [self setObject:data forKey:key];
}


- (NSArray *)sortDescriptorsForKey:(NSString *)key {
	return [NSKeyedUnarchiver unarchiveObjectWithData:[self objectForKey:key]];
}


@end

@implementation NSDictionary (TKSortDescriptorAdditions)

- (NSArray *)sortDescriptorsForKey:(NSString *)key {
	return [NSKeyedUnarchiver unarchiveObjectWithData:[self objectForKey:key]];
}

@end

@implementation NSMutableDictionary (TKSortDescriptorAdditions)

- (void)setSortDescriptors:(NSArray *)sortDescriptors forKey:(NSString *)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sortDescriptors];
	if (data) [self setObject:data forKey:key];
}

@end



@implementation NSIndexSet (TKAdditions)

+ (id)indexSetWithIndexSet:(NSIndexSet *)indexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[self class] alloc] initWithIndexSet:indexes] autorelease];
}


- (NSIndexSet *)indexesIntersectingIndexes:(NSIndexSet *)indexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSMutableIndexSet *intersectingIndexes = [NSMutableIndexSet indexSet];
	
	NSUInteger theIndex = [self firstIndex];
	
	while (theIndex != NSNotFound) {
		if ([indexes containsIndex:theIndex]) [intersectingIndexes addIndex:theIndex];
		
		theIndex = [self indexGreaterThanIndex:theIndex];
	}
	
	return [[intersectingIndexes copy] autorelease];
}


@end



@implementation NSMutableIndexSet (TKAdditions)

- (void)setIndexes:(NSIndexSet *)indexes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self removeAllIndexes];
	[self addIndexes:indexes];
}


@end



@implementation NSData (TKDescriptionAdditions)


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



@implementation NSMutableArray (TKAdditions)

- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [array count])]];
}


@end


@implementation NSObject (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
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

@implementation NSDictionary (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
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


@implementation NSArray (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
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



@implementation NSSet (TKDeepMutableCopy)

- (id)deepMutableCopy {
#if TK_DEBUG
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

