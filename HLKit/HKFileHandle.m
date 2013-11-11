//
//  HKFileHandle.m
//  HLKit
//
//  Created by Mark Douma on 1/19/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFileHandle.h>
#import <HLKit/HKFoundationAdditions.h>



enum {
	HKBrokenCreatorCode = 'MACS',
	HKBrokenFileType	= 'brok'
};

@interface HKFileHandle ()
@property (retain) NSString *path;
@end

@implementation HKFileHandle

@synthesize path;

+ (id)fileHandleForWritingAtPath:(NSString *)aPath {
	return [[[[self class] alloc] initForWritingAtPath:aPath] autorelease];
}


- (id)initForWritingAtPath:(NSString *)aPath {
	if ((self = [super init])) {
		[self setPath:aPath];
		FSRef parentRef;
		HFSUniStr255	forkName;
		
		OSStatus status = FSGetDataForkName(&forkName);
		
		if (status != noErr) {
			NSLog(@"[%@ %@] FSGetDataForkName() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
			[self release];
			return nil;
		}
		
		NSError *anError = nil;
		
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		BOOL isDir;
		
		if (!([fileManager fileExistsAtPath:aPath isDirectory:&isDir] && !isDir)) {
			if (![[aPath stringByDeletingLastPathComponent] getFSRef:&parentRef error:&anError]) {
				NSLog(@"[%@ %@] failed to get parentRef", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				[fileManager release];
				[self release];
				return nil;
			}
			
			// if a POSIX path name coming in has a slash / in the actual file name, it'll have been converted to a colon : by POSIX. This command needs a colon-delimited path, so it needs to be converted from colons back to slashes
			
			NSString *correctedFileName = [[aPath lastPathComponent] colonToSlash];
			UniCharCount correctedFileNameLength = [correctedFileName length];
			UniChar correctedFileNameUnicode[NAME_MAX];
			
			[correctedFileName getCharacters:correctedFileNameUnicode range:NSMakeRange(0, correctedFileNameLength)];
			
			FSCatalogInfo catalogInfo;
			
			FileInfo *fInfo = (FileInfo *)&catalogInfo.finderInfo;
			fInfo->fileType = HKBrokenFileType;
			fInfo->fileCreator = HKBrokenCreatorCode;
			fInfo->finderFlags = 0;
			Point point;
			point.v = 0;
			point.h = 0;
			fInfo->location = point;
			fInfo->reservedField = 0;
			
			status = FSCreateFileUnicode(&parentRef,
										 correctedFileNameLength,
										 correctedFileNameUnicode,
										 kFSCatInfoFinderInfo,
										 &catalogInfo,
										 &fileRef,
										 NULL);
			
			if (status != noErr) {
				NSLog(@"[%@ %@] FSCreateFileUnicode() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
				[fileManager release];
				[self release];
				return nil;
			}
			status = FSOpenFork(&fileRef, forkName.length, forkName.unicode, fsRdWrPerm, &forkRef);
			
			if (status != noErr) {
				NSLog(@"[%@ %@] FSOpenFork() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
				[fileManager release];
				[self release];
				return nil;
			}
			
		} else {
			
			if (![aPath getFSRef:&fileRef error:&anError]) {
				NSLog(@"[%@ %@] failed to getFSRef:error:, error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), anError);
				[fileManager release];
				[self release];
				return nil;
			}
			
			status = FSOpenFork(&fileRef, forkName.length, forkName.unicode, fsRdWrPerm, &forkRef);
			if (status != noErr) {
				NSLog(@"[%@ %@] FSOpenFork() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
				[fileManager release];
				[self release];
				return nil;
			}
		}
		
		offsetInFile = 0;
		[fileManager release];
	}
	return self;
}


- (void)dealloc {
	[path release];
	[self closeFile];
	[super dealloc];
}



- (void)writeData:(NSData *)aData {
	unsigned long long dataLength = [aData length];
	
	OSStatus status = noErr;
	ByteCount actualCount = 0;
	
	status = FSWriteFork(forkRef, fsAtMark + noCacheMask, 0, dataLength, [aData bytes], &actualCount);
	
	if (status != noErr) NSLog(@"[%@ %@] FSWriteFork() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
	
	offsetInFile += actualCount;
	
}

- (void)synchronizeFile {
	if (forkRef != -1) {
		OSStatus status = FSFlushFork(forkRef);
		if (status != noErr) NSLog(@"[%@ %@] FSFlushFork(forkRef) returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
	}
}


- (void)closeFile {
	[self synchronizeFile];
	
	if (forkRef != -1) {
		OSStatus status = FSCloseFork(forkRef);
		if (status != noErr) NSLog(@"[%@ %@] FSCloseFork(forkRef) returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
		
		forkRef = -1;
		
		FSCatalogInfo catalogInfo;
		
		FileInfo *fInfo = (FileInfo *)&catalogInfo.finderInfo;
		fInfo->fileType = 0;
		fInfo->fileCreator = 0;
		fInfo->finderFlags = 0;
		Point point;
		point.v = 0;
		point.h = 0;
		fInfo->location = point;
		fInfo->reservedField = 0;
		
		status = FSSetCatalogInfo(&fileRef, kFSCatInfoFinderInfo, &catalogInfo);
		if (status != noErr) NSLog(@"[%@ %@] FSSetCatalogInfo() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
	}
	
}


- (unsigned long long)offsetInFile {
	if (forkRef != -1) {
		OSStatus status = noErr;
		SInt64 position = 0;
		status = FSGetForkPosition(forkRef, &position);
		if (status != noErr) NSLog(@"[%@ %@] FSGetForkPosition() returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
		return position; 
	}
	return 0;
}


- (unsigned long long)seekToEndOfFile {
	if (forkRef != -1) {
		OSStatus status = noErr;
		status = FSSetForkPosition(forkRef, fsFromLEOF, 0);
		if (status != noErr) NSLog(@"[%@ %@] FSSetForkPosition(forkRef) returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
		return [self offsetInFile];
	}
	return 0;
}


- (void)seekToFileOffset:(unsigned long long)anOffset {
	if (forkRef != -1) {
		OSStatus status = noErr;
		status = FSSetForkPosition(forkRef, fsFromStart, (SInt64)anOffset);
		if (status != noErr) NSLog(@"[%@ %@] FSSetForkPosition(forkRef) returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
	}
}


- (void)truncateFileAtOffset:(unsigned long long)anOffset {
	if (forkRef != -1) {
		OSStatus status = noErr;
		status = FSSetForkSize(forkRef, fsFromStart, (SInt64)anOffset);
		if (status != noErr) NSLog(@"[%@ %@] FSSetForkSize(forkRef) returned %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (int)status);
	}
}



@end







