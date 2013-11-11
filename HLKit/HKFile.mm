//
//  HKFile.mm
//  HLKit
//
//  Created by Mark Douma on 9/1/2010.
//  Copyright (c) 2009-2012 Mark Douma LLC. All rights reserved.
//

#import <HLKit/HKFile.h>
#import <HLKit/HKFolder.h>
#import <HLKit/HKFoundationAdditions.h>
#import "HKPrivateInterfaces.h"
#import <HLKit/HKFileHandle.h>
#import <HL/HL.h>


#import <CoreServices/CoreServices.h>

#define HK_DEBUG 0

#define HK_LAZY_INIT 1


//#define HK_COPY_BUFFER_SIZE 524288

//#define HK_COPY_BUFFER_SIZE 262144

#define HK_COPY_BUFFER_SIZE 262144


using namespace HLLib;
using namespace HLLib::Streams;


@implementation HKFile


- (id)initWithParent:(HKFolder *)aParent directoryFile:(CDirectoryFile *)aFile container:(id)aContainer {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithParent:aParent childNodes:nil sortDescriptors:nil container:aContainer])) {
		_privateData = aFile;
		
		isExtractable = static_cast<const CDirectoryFile *>(_privateData)->GetExtractable();
		isVisible = isExtractable;
		
		isLeaf = YES;
		
#if !(HK_LAZY_INIT)
		const hlChar *cName = static_cast<const CDirectoryFile *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
		nameExtension = [[name pathExtension] retain];
		
		hlUInt fileSize = 0;
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->GetFileSize(static_cast<const CDirectoryFile *>(_privateData), fileSize);
		size = [[NSNumber numberWithUnsignedLongLong:(unsigned long long)fileSize] retain];
		
		type = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)nameExtension, NULL);
		
		kind = [[[NSWorkspace sharedWorkspace] localizedDescriptionForType:type] retain];
		
		if (kind == nil) {
			LSCopyKindStringForTypeInfo(kLSUnknownType, kLSUnknownCreator, (CFStringRef)nameExtension, (CFStringRef *)&kind);
		}
		
		fileType = HKFileTypeOther;
		
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		
		if (isExtractable) {
			if ([workspace type:type conformsToType:(NSString *)kUTTypeHTML]) {
				fileType = HKFileTypeHTML;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeText]) {
				fileType = HKFileTypeText;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeImage]) {
				fileType = HKFileTypeImage;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeAudio]) {
				fileType = HKFileTypeSound;
			} else if ([workspace type:type conformsToType:(NSString *)kUTTypeMovie]) {
				fileType = HKFileTypeMovie;
			}
			
		} else {
			fileType = HKFileTypeNotExtractable;
		}
#endif
		
	}
	return self;
}


- (void)dealloc {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super dealloc];
}

#if (HK_LAZY_INIT)

- (NSString *)name {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (name == nil) {
		const hlChar *cName = static_cast<const CDirectoryFile *>(_privateData)->GetName();
		if (cName) name = [[NSString stringWithCString:cName encoding:NSUTF8StringEncoding] retain];
	}
	return name;
}

- (NSString *)nameExtension {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (nameExtension == nil) nameExtension = [[[self name] pathExtension] retain];
	return nameExtension;
}

- (NSString *)type {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (type == nil) {
		type = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[self nameExtension], NULL);
	}
	return type;
}

- (NSString *)kind {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (kind == nil) {
		kind = [[[NSWorkspace sharedWorkspace] localizedDescriptionForType:[self type]] retain];
		if (kind == nil) {
			LSCopyKindStringForTypeInfo(kLSUnknownType, kLSUnknownCreator, (CFStringRef)[self nameExtension], (CFStringRef *)&kind);
		}
	}
	return kind;
}
		
- (NSNumber *)size {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (size == nil) {
		hlUInt fileSize = 0;
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->GetFileSize(static_cast<const CDirectoryFile *>(_privateData), fileSize);
		size = [[NSNumber numberWithUnsignedLongLong:(unsigned long long)fileSize] retain];
	}
	return size;
}

- (HKFileType)fileType {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (fileType == HKFileTypeNone) {
		
		fileType = HKFileTypeOther;
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		
		NSString *aType = [self type];
		
		if (isExtractable) {
			if ([workspace type:aType conformsToType:(NSString *)kUTTypeHTML]) {
				fileType = HKFileTypeHTML;
			} else if ([workspace type:aType conformsToType:(NSString *)kUTTypeText]) {
				fileType = HKFileTypeText;
			} else if ([workspace type:aType conformsToType:(NSString *)kUTTypeImage]) {
				fileType = HKFileTypeImage;
			} else if ([workspace type:aType conformsToType:(NSString *)kUTTypeAudio]) {
				fileType = HKFileTypeSound;
			} else if ([workspace type:aType conformsToType:(NSString *)kUTTypeMovie]) {
				fileType = HKFileTypeMovie;
			}
			
		} else {
			fileType = HKFileTypeNotExtractable;
		}
	}
	return fileType;
}

#endif


- (BOOL)beginWritingToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	if (isExtractable == NO) {
		if (outError) *outError = [NSError errorWithDomain:HKErrorDomain code:HKErrorNotExtractable userInfo:nil];
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
	
	_fH = [[HKFileHandle fileHandleForWritingAtPath:aPath] retain];
	if (_fH == nil) {
		NSLog(@"[%@ %@] failed to create fileHandle at path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
		return NO;
	}
	
	_iS = 0;
	IStream *pInput = static_cast<IStream *>(_iS);
	
	if (!static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->CreateStream(static_cast<const CDirectoryFile *>(_privateData), pInput)) {
		NSLog(@"[%@ %@] file->GetPackage()-CreateStream() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[(HKFileHandle *)_fH release];
		_fH = nil;
		return NO;
	}
	_iS = pInput;
	
	if (!static_cast<IStream *>(_iS)->Open(HL_MODE_READ)) {
		NSLog(@"[%@ %@] pInput->Open(HL_MODE_READ) failed for item == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self);
		static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
		[(HKFileHandle *)_fH release];
		_fH = nil;
		return NO;
	}
	
	return YES;
}


- (BOOL)continueWritingPartialBytesOfLength:(NSUInteger *)partialBytesLength error:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outError) *outError = nil;
	
//	hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
	hlByte buffer[HK_COPY_BUFFER_SIZE];
	
	unsigned long long currentBytesRead = static_cast<IStream *>(_iS)->Read(buffer, sizeof(buffer));
	
	if (currentBytesRead == 0) {
		if (partialBytesLength) *partialBytesLength = 0;
		return NO;
	}
	
//	NSData *writeData = [[NSData alloc] initWithBytes:buffer length:currentBytesRead];
	
	NSData *writeData = [[NSData alloc] initWithBytesNoCopy:buffer length:currentBytesRead freeWhenDone:NO];
	
//	NSData *writeData = [[NSData alloc] initWithBytes:buffer length:currentBytesRead];
	if (writeData) {
		[(HKFileHandle *)_fH writeData:writeData];
	}
	[writeData release];
	
	if (partialBytesLength) *partialBytesLength = currentBytesRead;
	return YES;
}


- (BOOL)finishWritingWithError:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (outError) *outError = nil;
	
	static_cast<IStream *>(_iS)->Close();
	static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
	_iS = 0;
	
	[(HKFileHandle *)_fH closeFile];
	[(HKFileHandle *)_fH release];
	_fH = nil;
	
	return YES;
}


- (BOOL)cancelWritingAndRemovePartialFileWithError:(NSError **)outError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (outError) *outError = nil;
	
	static_cast<IStream *>(_iS)->Close();
	static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->ReleaseStream(static_cast<IStream *>(_iS));
	_iS = 0;
	
	NSString *filePath = [[[(HKFileHandle *)_fH path] retain] autorelease];
	
	[(HKFileHandle *)_fH closeFile];
	[(HKFileHandle *)_fH release];
	_fH = nil;
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if (![fileManager removeItemAtPath:filePath error:outError]) {
		NSLog(@"[%@ %@] failed to delete partial file at %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), filePath);
	}
	[fileManager release];
	
	return YES;
}


- (BOOL)writeToFile:(NSString *)aPath assureUniqueFilename:(BOOL)assureUniqueFilename resultingPath:(NSString **)resultingPath error:(NSError **)anError {
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (anError) *anError = nil;
	if (isExtractable == NO) {
		if (anError) *anError = [NSError errorWithDomain:HKErrorDomain code:HKErrorNotExtractable userInfo:nil];
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
	
	HKFileHandle *fileHandle = [HKFileHandle fileHandleForWritingAtPath:aPath];
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
	
//	hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
	hlByte buffer[HK_COPY_BUFFER_SIZE];
	
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
#if HK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (isExtractable) {
		NSMutableData *mData = [NSMutableData data];
		hlBool bResult = hlFalse;
		
		IStream *pInput = 0;
		if (static_cast<const CDirectoryFile *>(_privateData)->GetPackage()->CreateStream(static_cast<const CDirectoryFile *>(_privateData), pInput)) {
			if (pInput->Open(HL_MODE_READ)) {
				
				hlUInt totalBytesExtracted = 0;
//				hlByte buffer[HL_DEFAULT_COPY_BUFFER_SIZE];
				hlByte buffer[HK_COPY_BUFFER_SIZE];
				
				while (hlTrue) {
					hlUInt currentBytesRead = pInput->Read(buffer, sizeof(buffer));
					
					if (currentBytesRead == 0) {
						bResult = (totalBytesExtracted == pInput->GetStreamSize());
						
						if (bResult == NO) {
							
						}
						
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


