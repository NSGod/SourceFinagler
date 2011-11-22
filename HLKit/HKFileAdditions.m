//
//  HKFileAdditions.m
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFileAdditions.h>
#import <HLKit/HKFoundationAdditions.h>


#define MD_DEBUG 0

@implementation HKFile (MDAdditions)


- (NSString *)stringValue {
	return [self stringValueByExtractingToTempFile:NO];
}

- (NSString *)stringValueByExtractingToTempFile:(BOOL)shouldExtractToTempFile {
	if (fileType != HKFileTypeHTML && fileType != HKFileTypeText) return nil;
	
	NSData *textData = [self data];
	if (textData == nil) {
		NSLog(@"[%@ %@] failed to extract data!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	NSString *stringValue = nil;
	
	if (shouldExtractToTempFile) {
		NSString *tempPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.markdouma.SourceAddonFinagler"] stringByAssuringUniqueFilename];
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		if (![fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			NSLog(@"[%@ %@] failed to create tempDirectory to extract file in!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		NSString *writePath = [tempPath stringByAppendingPathComponent:@"temp.txt"];
		if ([textData writeToFile:writePath atomically:NO]) {
			NSStringEncoding usedEncoding = NSUTF8StringEncoding;
			NSError *stringError = nil;
			stringValue = [NSString stringWithContentsOfFile:writePath usedEncoding:&usedEncoding error:&stringError];
			
			NSLog(@"[%@ %@] usedEncoding == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSString localizedNameOfStringEncoding:usedEncoding]);
			if (stringValue == nil) {
				NSLog(@"[%@ %@] string creation error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringError);
			}
		}
		if (![fileManager removeItemAtPath:tempPath error:NULL]) {
			NSLog(@"[%@ %@] failed to cleanup temp folder!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
	} else {
		stringValue = [[[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding] autorelease];
		if (stringValue == nil) {
			NSLog(@"[%@ %@] failed to create string with NSUTF8StringEncoding", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			
			stringValue = [[[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding] autorelease];
			if (stringValue == nil) {
				NSLog(@"[%@ %@] failed to create string with NSASCIIStringEncoding", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				
				stringValue = [[[NSString alloc] initWithData:textData encoding:NSISOLatin1StringEncoding] autorelease];
				if (stringValue == nil) {
					NSLog(@"[%@ %@] failed to create string with NSISOLatin1StringEncoding, data == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), textData);
					stringValue = @"<failed to create string using UTF8, ASCII, or ISO Latin 1 encodings>";
				}
			}
		}
	}
	return stringValue;
}


@end
