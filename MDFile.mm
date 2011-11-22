//
//  MDFile.mm
//  Source Finagler
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDFile.h"
#import "MDFolder.h"
#import <CoreServices/CoreServices.h>
#import "MDFoundationAdditions.h"
#import "MDHLPrivateInterfaces.h"
#import <HL/HL.h>

#import "MDFileHandle.h"


#define MD_DEBUG 0


using namespace HLLib;
using namespace HLLib::Streams;


@implementation MDFile


- (id)initWithParent:(MDFolder *)aParent directoryFile:(CDirectoryFile *)aFile container:(id)aContainer {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithParent:aParent children:nil sortDescriptors:nil container:aContainer])) {
		_privateData = aFile;

		const hlChar *cName = static_cast<const CDirectoryFile *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
		nameExtension = [[name pathExtension] retain];
		isExtractable = static_cast<const CDirectoryFile *>(_privateData)->GetExtractable();
		isVisible = isExtractable;
		
		hlUInt fileSize = 0;
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->GetFileSize(static_cast<const CDirectoryFile *>(_privateData), fileSize);
		size = [[NSNumber numberWithUnsignedLongLong:(unsigned long long)fileSize] retain];
		
		type = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)nameExtension, NULL);
		
		kind = [[[NSWorkspace sharedWorkspace] localizedDescriptionForType:type] retain];
		
		if (kind == nil) {
			LSCopyKindStringForTypeInfo(kLSUnknownType, kLSUnknownCreator, (CFStringRef)nameExtension, (CFStringRef *)&kind);
		}
		
		fileType = MDFileTypeOther;
		
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		
		if (isExtractable) {
			if ([workspace type:type conformsToType:(NSString *)kUTTypeHTML]) {
				fileType = MDFileTypeHTML;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeText]) {
				fileType = MDFileTypeText;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeImage]) {
				fileType = MDFileTypeImage;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeAudio]) {
				fileType = MDFileTypeSound;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeMovie]) {
				fileType = MDFileTypeMovie;
			}
			
		} else {
			fileType = MDFileTypeNotExtractable;
		}
		isLeaf = YES;
	}
	return self;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super dealloc];
}


- (BOOL)beginWritingToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	if (isExtractable == NO) {
		if (outError) *outError = [NSError errorWithDomain:MDHLErrorDomain code:MDHLErrorNotExtractable userInfo:nil];
		return NO;
	}
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSString *parentDirectory = [aPath stringByDeletingLastPathComponent];
	
	if (![fileManager createDirectoryAtPath:parentDirectory withIntermediateDirectories:YES attributes:nil error:outError]) {
		NSLog(@"[%@ %@] failed to create directory at path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parentDirectory);
		return NO;
	}
	if (assureUniqueFilename) aPath = [aPath stringByAssuringUniqueFilename];
	
	if (resultingPath) *resultingPath = aPath;
	
	_fH = [[MDFileHandle fileHandleForWritingAtPath:aPath] retain];
	if (_fH == nil) {
		NSLog(@"[%@ %@] failed to create fileHandle at path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
		return NO;
	}
	
	_iS = 0;
	IStream *pInput = static_cast<IStream *>(_iS);
	
	if (!static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->CreateStream(static_cast<const CDirectoryFile *>(_privateData), pInput)) {
		NSLog(@"[%@ %@] file->GetPackage()-CreateStream() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	_iS = pInput;
	
	if (!static_cast<IStream *>(_iS)->Open(HL_MODE_READ)) {
		NSLog(@"[%@ %@] pInput->Open(HL_MODE_READ) failed for item == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self);
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
		return NO;
	}
	
	return YES;
}


- (BOOL)continueWritingPartialBytesOfLength:(NSUInteger *)partialBytesLength error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	
	hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
	
	unsigned long long currentBytesRead = static_cast<IStream *>(_iS)->Read(buffer, sizeof(buffer));
	
	if (currentBytesRead == 0) {
		if (partialBytesLength) *partialBytesLength = 0;
		return NO;
	}
	
	NSData *writeData = [[NSData alloc] initWithBytes:buffer length:currentBytesRead];
	if (writeData) {
		[(MDFileHandle *)_fH writeData:writeData];
	}
	[writeData release];
	
	if (partialBytesLength) *partialBytesLength = currentBytesRead;
	return YES;
}


- (BOOL)finishWritingWithError:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (outError) *outError = nil;
	
	static_cast<IStream *>(_iS)->Close();
	static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
	_iS = 0;
	
	[(MDFileHandle *)_fH closeFile];
	[(MDFileHandle *)_fH release];
	_fH = nil;
	
	return YES;
}


- (BOOL)cancelWritingAndRemovePartialFileWithError:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (outError) *outError = nil;
	
	static_cast<IStream *>(_iS)->Close();
	static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
	_iS = 0;
	
	NSString *filePath = [[[(MDFileHandle *)_fH path] retain] autorelease];
	
	[(MDFileHandle *)_fH closeFile];
	[(MDFileHandle *)_fH release];
	_fH = nil;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if (![fileManager removeItemAtPath:filePath error:outError]) {
		NSLog(@"[%@ %@] failed to delete partial file at %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), filePath);
	}
	[fileManager release];
	
	return YES;
}


- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)anError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (anError) *anError = nil;
	if (isExtractable == NO) {
		if (anError) *anError = [NSError errorWithDomain:MDHLErrorDomain code:MDHLErrorNotExtractable userInfo:nil];
		return NO;
	}
	
	BOOL success = YES;
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSString *parentDirectory = [aPath stringByDeletingLastPathComponent];
	
	if (![fileManager createDirectoryAtPath:parentDirectory withIntermediateDirectories:YES attributes:nil error:anError]) {
		NSLog(@"[%@ %@] failed to create directory at path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), parentDirectory);
		return NO;
	}
	if (assureUniqueFilename) aPath = [aPath stringByAssuringUniqueFilename];
	
	MDFileHandle *fileHandle = [MDFileHandle fileHandleForWritingAtPath:aPath];
	if (fileHandle == nil) {
		NSLog(@"[%@ %@] failed to create fileHandle at path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
		return NO;
	}
	
	IStream *pInput = 0;
	if (!static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->CreateStream(static_cast<const CDirectoryFile *>(_privateData), pInput)) {
		NSLog(@"[%@ %@] file->GetPackage()-CreateStream() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	if (!pInput->Open(HL_MODE_READ)) {
		NSLog(@"[%@ %@] pInput->Open(HL_MODE_READ) failed for item == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self);
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(pInput);
		return NO;
	}
	
	unsigned long long totalBytesWritten = 0;
	
	hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
	
	while (hlTrue) {
		unsigned long long currentBytesRead = pInput->Read(buffer, sizeof(buffer));
		
		if (currentBytesRead == 0) {
			success = (totalBytesWritten == pInput->GetStreamSize());
			break;
		}
		
		NSData *writeData = [[NSData alloc] initWithBytes:buffer length:currentBytesRead];
		if (writeData) {
			[fileHandle writeData:writeData];
		}
		[writeData release];
		
		totalBytesWritten += currentBytesRead;
		
	}
	pInput->Close();
	static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(pInput);
	
	if (resultingPath) *resultingPath = aPath;
	
	[fileHandle closeFile];
	
	return success;
}



- (NSData *)data {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isExtractable) {
		NSMutableData *mData = [NSMutableData data];
		hlBool bResult = hlFalse;
		
		IStream *pInput = 0;
		if (static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->CreateStream(static_cast<const CDirectoryFile *>(_privateData), pInput)) {
			if (pInput->Open(HL_MODE_READ)) {
				
				hlUInt totalBytesExtracted = 0;
				hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
				
				while (hlTrue) {
					hlUInt currentBytesRead = pInput->Read(buffer, sizeof(buffer));
					
					if (currentBytesRead == 0) {
						bResult = (totalBytesExtracted == pInput->GetStreamSize());
						break;
					}
					[mData appendBytes:buffer length:currentBytesRead];
					
					totalBytesExtracted += currentBytesRead;
				}
				
				pInput->Close();
			}
			static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(pInput);
		}
		return [[mData copy] autorelease];
	}
	return nil;
}


@end


