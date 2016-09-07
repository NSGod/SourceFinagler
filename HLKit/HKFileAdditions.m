//
//  HKFileAdditions.m
//  HLKit
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFileAdditions.h>
#import <HLKit/HKArchiveFile.h>
#import "HKFoundationAdditions.h"

#import <Cocoa/Cocoa.h>

#import <QTKit/QTKit.h>

#import <TextureKit/TKImage.h>
#import <TextureKit/TKVTFImageRep.h>


#define HK_DEBUG 0

@implementation HKFile (HKAdditions)


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
	
	NSString *containerFilePath = [(HKArchiveFile *)container filePath];
	
	if (shouldExtractToTempFile) {
		NSString *tempPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.markdouma.SourceAddonFinagler"] stringByAssuringUniqueFilename];
		NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
		if (![fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			NSLog(@"[%@ %@] failed to create tempDirectory to extract file in!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		NSString *writePath = nil;
		
		if (containerFilePath) {
			writePath = [tempPath stringByAppendingPathComponent:[[containerFilePath lastPathComponent] stringByAppendingString:@".txt"]];
		} else {
			writePath = [tempPath stringByAppendingPathComponent:@"temp.txt"];
		}
		
		NSString *stringValue = nil;
		
		if ([textData writeToFile:writePath atomically:NO]) {
			NSStringEncoding usedEncoding = NSUTF8StringEncoding;
			NSError *stringError = nil;
			stringValue = [NSString stringWithContentsOfFile:writePath usedEncoding:&usedEncoding error:&stringError];
#if HK_DEBUG
			NSLog(@"[%@ %@] <%@> usedEncoding == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [writePath lastPathComponent],[NSString localizedNameOfStringEncoding:usedEncoding]);
#endif
			if (stringValue == nil) {
				NSLog(@"[%@ %@] string creation error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), stringError);
			}
		}
		if (![fileManager removeItemAtPath:tempPath error:NULL]) {
			NSLog(@"[%@ %@] failed to cleanup temp folder!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
		return stringValue;
	} else {
		NSString *stringValue = [[[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding] autorelease];
		if (stringValue == nil) {
			NSLog(@"[%@ %@] <%@> failed to create string with NSUTF8StringEncoding", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [containerFilePath lastPathComponent]);
			
			stringValue = [[[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding] autorelease];
			if (stringValue == nil) {
				NSLog(@"[%@ %@] <%@> failed to create string with NSASCIIStringEncoding", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [containerFilePath lastPathComponent]);
				
				stringValue = [[[NSString alloc] initWithData:textData encoding:NSISOLatin1StringEncoding] autorelease];
				if (stringValue == nil) {
					NSLog(@"[%@ %@] <%@> failed to create string with NSISOLatin1StringEncoding, data == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [containerFilePath lastPathComponent], textData);
					stringValue = @"<failed to create string using UTF8, ASCII, or ISO Latin 1 encodings>";
				}
			}
		}
		return stringValue;
	}
	return nil;
}


- (NSSound *)sound {
	if (fileType != HKFileTypeSound) return nil;
	NSData *soundData = [self data];
	if (soundData) return [[[NSSound alloc] initWithData:soundData] autorelease];
	return nil;
}


- (NSImage *)image {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSImage *theImage = nil;
	if (fileType == HKFileTypeImage) {
		NSData *data = [self data];
		if (data) {
			if ([type isEqualToString:TKVTFType]) {
				NSError *outError = nil;
				theImage = [[[TKImage alloc] initWithData:data error:&outError] autorelease];
//				theImage = [[[TKImage alloc] initWithData:data firstRepresentationOnly:YES error:&outError] autorelease];
				if (theImage == nil) {
					NSLog(@"[%@ %@] failed to create TKImage! error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), outError);
					return nil;
				}
				[self setVersion:[(TKImage *)theImage version]];
				[self setCompression:[(TKImage *)theImage compression]];
				[self setHasMipmaps:([(TKImage *)theImage hasMipmaps] ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @""))];
				[self setAlpha:([(TKImage *)theImage hasAlpha] ? NSLocalizedString(@"Yes", @"") : NSLocalizedString(@"No", @""))];
			} else {
				theImage = [[[NSImage alloc] initWithData:data] autorelease];
			}
		}
		if (theImage) {
			NSSize imageSize = [theImage size];
			[self setDimensions:[NSString stringWithFormat:NSLocalizedString(@"%lu x %lu", @""), (unsigned long)imageSize.width, (unsigned long)imageSize.height]];
		}
	} else if (fileType == HKFileTypeOther ||
			   fileType == HKFileTypeText ||
			   fileType == HKFileTypeHTML ||
			   fileType == HKFileTypeNotExtractable) {
		theImage = [HKItem copiedImageForItem:self];
		[theImage setSize:NSMakeSize(128.0, 128.0)];
	}
	return theImage;
}


- (QTMovie *)movie {
	QTMovie *movie = nil;
	if (fileType == HKFileTypeMovie) {
		NSData *data = [self data];
		if (data) {
			NSError *error = nil;
			movie = [QTMovie movieWithData:data error:&error];
			if (!movie) {
				NSLog(@"[%@ %@] failed to create movie (error == %@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
			}
		}
	}
	return movie;
}


@end
