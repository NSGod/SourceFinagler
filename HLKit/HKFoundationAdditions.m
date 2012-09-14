//
//  HKFoundationAdditions.m
//  HKFoundationAdditions
//
//  Created by Mark Douma on 12/03/2007.
//  Copyright (c) 2007-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFoundationAdditions.h>
#import <sys/syslimits.h>
#import <openssl/sha.h>

#define HK_DEBUG 0


@implementation NSString (HKAdditions)


+ (NSString *)stringWithFSRef:(const FSRef *)anFSRef {
#if HK_DEBUG
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
#if HK_DEBUG
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
#if HK_DEBUG
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


- (NSComparisonResult)caseInsensitiveNumericalCompare:(NSString *)string {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options: NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch];
}

- (NSComparisonResult)localizedCaseInsensitiveNumericalCompare:(NSString *)string {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self compare:string options:NSLiteralSearch | NSCaseInsensitiveSearch | NSNumericSearch range:NSMakeRange(0, [string length]) locale:[NSLocale currentLocale]];
}


- (BOOL)containsString:(NSString *)aString {
#if HK_DEBUG
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


@end



@implementation NSMutableArray (HKAdditions)

- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)anIndex {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[self insertObjects:array atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(anIndex, [array count])]];
}


@end

