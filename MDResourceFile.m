//
//  MDResourceFile.m
//  Font Finagler
//
//  Created by Mark Douma on 7/22/2007.
//  Copyright © 2007 Mark Douma. All rights reserved.
//



#import "MDResourceFile.h"
#import "MDFoundationAdditions.h"
#import "MDFileManager.h"
#import "MDResource.h"


#pragma mark model
#define MD_DEBUG 0


NSString * const MDResourceFileErrorDomain			= @"com.markdouma.FontFinagler.ResourceFileErrorDomain";


#define badNameLength (0xffffU)


OSErr MDCheckResourceFileSanity(const FSRef *fsr, HFSUniStr255 *forkName, Boolean *sane) {
    FSIORefNum		refNum;			/* file refnum */
    ByteCount		count;			/* number of bytes to read */
    SInt64			logEOF;			/* logical EOF */
    unsigned char	*map;			/* pointer to resource map */
    UInt32	dataLWA;		/* offset in file of data end */
    UInt32	mapLWA;			/* offset in file of map end */
    UInt16	typeFWA = 0;		/* offset from map begin to type list */
    UInt16	nameFWA = 0;		/* offset from map begin to name list */
    unsigned char	*pType;			/* pointer into type list */
    unsigned char	*pName;			/* pointer to start of name list */
    unsigned char	*pMapEnd;		/* pointer to end of map */
    SInt16			nType;			/* number of resource types in map */
    unsigned char	*pTypeEnd;		/* pointer to end of type list */
    SInt16			nRes;			/* number of resources of given type */
    UInt16	refFWA;			/* offset from type list to ref list */
    unsigned char	*pRef;			/* pointer into reference list */
    unsigned char	*pRefEnd;		/* pointer to end of reference list */
    UInt16	resNameFWA;		/* offset from name list to resource name */
    unsigned char	*pResName;		/* pointer to resource name */
    UInt32	resDataFWA;		/* offset from data begin to resource data */
    Boolean			mapOK;			/* true if map is sane */
    OSErr			rCode;			/* error code */
	/*	so all the xxxxFWA fields are offsets from the start of the file	*/
	
    struct {
		UInt32	dataFWA;		/* offset in file of data */
		UInt32	mapFWA;			/* offset in file of map */
		UInt32	dataLen;		/* data area length */
		UInt32	mapLen;			/* map area length */
		
    } header;
    
	*sane = false;
	
    /* Open the resource file. */
    if (forkName->length == badNameLength) {
		return noErr;
    }
    rCode = FSOpenFork(fsr, forkName->length, forkName->unicode, fsRdPerm, &refNum);
    if (rCode) {
		if (rCode == fnfErr) {
			return noErr;
		} else {
			return rCode;
		}
    }
    
    /* Get the logical eof of the file. */
    rCode = FSGetForkSize(refNum, &logEOF);
    if (rCode) {
		return rCode;
	}
    if (!logEOF) {
		rCode = FSCloseFork(refNum);
		if (rCode) {
			return rCode;
		}
		return noErr;
	}
	
	/* Read and validate the resource header. */
	count = 16;
	rCode = FSReadFork(refNum, fsFromStart, 0, count, &header, &count);
	if (rCode) {
		FSCloseFork(refNum);
		return rCode;
	}	
	
	dataLWA = NSSwapBigIntToHost(header.dataFWA) + NSSwapBigIntToHost(header.dataLen);
	
	mapLWA = NSSwapBigIntToHost(header.mapFWA) + NSSwapBigIntToHost(header.mapLen);
	
	header.dataFWA = NSSwapBigIntToHost(header.dataFWA);
	header.mapFWA = NSSwapBigIntToHost(header.mapFWA);
	header.dataLen = NSSwapBigIntToHost(header.dataLen);
	header.mapLen = NSSwapBigIntToHost(header.mapLen);
	
	
	mapOK = (count == 16 && header.mapLen > 28 && header.dataFWA < 0x01000000 && header.mapFWA < 0x01000000 && dataLWA <= logEOF && mapLWA <= logEOF && (dataLWA <= header.mapFWA || mapLWA <= header.dataFWA));
	
	/* Read the resource map. */
	map = nil;
	
	if (mapOK) {
		map = (unsigned char *)NewPtr(header.mapLen);
		count = header.mapLen;
		
		rCode = FSReadFork(refNum, fsFromStart, header.mapFWA, count, map, &count);
		if (!rCode) {
			typeFWA = NSSwapBigShortToHost(*(UInt16 *)(map + 24));
			nameFWA = NSSwapBigShortToHost(*(UInt16 *)(map + 26));
			
			mapOK = typeFWA == 28 && nameFWA >= typeFWA && nameFWA <= header.mapLen && !(typeFWA & 1) && !(nameFWA & 1);
		}
		
		/* Verify the type list, reference lists, and name list. */
		if (mapOK) {
			pType = map + typeFWA;
			pName = map + nameFWA;
			pMapEnd = map + header.mapLen;
			nType = NSSwapBigShortToHost(*(SInt16 *)pType) + 1;
			pType += 2;
			pTypeEnd = pType + (nType << 3);
			
			mapOK = pTypeEnd <= pMapEnd;
			
			if (mapOK) {
				while (pType < pTypeEnd) {
					nRes = NSSwapBigShortToHost(*(SInt16 *)(pType + 4)) + 1;
					refFWA = NSSwapBigShortToHost(*(UInt16 *)(pType + 6));
					pRef = map + typeFWA + refFWA;
					pRefEnd = pRef + 12 * nRes;
					if (!(mapOK = pRef >= pTypeEnd && pRef < pName && !(refFWA & 1))) {
						break;
					}
					
					while (pRef < pRefEnd) {
						resNameFWA = NSSwapBigShortToHost(*(UInt16 *)(pRef + 2));
						if (resNameFWA != 0xFFFF) {
							pResName = pName + resNameFWA;
							if (!(mapOK = pResName + *pResName < pMapEnd)) {
								break;
							}
						}
						
						resDataFWA = NSSwapBigIntToHost(*(UInt32 *)(pRef + 4)) & 0x00FFFFFF;
						if (!(mapOK = header.dataFWA + resDataFWA < dataLWA)) {
							break;
						}
						pRef += 12;
					}
					if (!mapOK) {
						break;
					}
					pType += 8;
				}
			}
		}
	}
    
    /* Dispose of the resource map, close the file and return. */
    if (map) {
		DisposePtr( (Ptr) map);
	}
    if (rCode == noErr) {
		rCode = FSCloseFork(refNum);
    } else {
		(void) FSCloseFork(refNum);
    }
    *sane = mapOK;
	if (mapOK == NO) rCode = mapReadErr;
    return rCode;
}



@interface MDResourceFile (MDPrivate)

- (BOOL)saveChanges:(NSError **)outError;

- (BOOL)setAttributeFlags:(ResAttributes)attributes forResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)outError;
- (NSData *)dataForResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)outError;
- (BOOL)removeDataForResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)outError;
- (BOOL)addData:(NSData *)aData resourceType:(ResType)aType resourceID:(ResID)anID resourceName:(NSString *)aName error:(NSError **)outError;

@end


@implementation MDResourceFile


// read-only; which fork is determined automatically
- (id)initWithContentsOfFile:(NSString *)aPath error:(NSError **)outError {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath] error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)aURL error:(NSError **)outError {
	return [self initWithContentsOfURL:aURL permission:MDReadPermission fork:MDAnyFork error:outError];
}


// read/write; the 'updating' comes from NSFileHandle
- (id)initForUpdatingWithContentsOfFile:(NSString *)aPath fork:(MDFork)aFork error:(NSError **)outError {
	return [self initForUpdatingWithContentsOfURL:[NSURL fileURLWithPath:aPath] fork:aFork error:outError];
}

- (id)initForUpdatingWithContentsOfURL:(NSURL *)aURL fork:(MDFork)aFork error:(NSError **)outError {
	return [self initWithContentsOfURL:aURL permission:MDReadWritePermission fork:aFork error:outError];
}


- (id)initWithContentsOfFile:(NSString *)aPath permission:(MDPermission)aPermission fork:(MDFork)aFork error:(NSError **)outError {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath] permission:aPermission fork:aFork error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)aURL permission:(MDPermission)aPermission fork:(MDFork)aFork error:(NSError **)outError {
	if (outError) *outError = nil;
	
	BOOL isDir;
	
	filePath = [[aURL path] retain];
	
	BOOL itemExists = ([[NSFileManager defaultManager] fileExistsAtPath:[aURL path] isDirectory:&isDir] && !isDir);
	
	
	OSErr			err = noErr;
	FSRef			fileRef;
	
	UInt64			resourceForkSize = 0;
	UInt64			dataForkSize	 = 0;
	FSCatalogInfo	fileInfo;
	
	if (itemExists && CFURLGetFSRef((CFURLRef)aURL, &fileRef)) {
		err = FSGetCatalogInfo(&fileRef, kFSCatInfoDataSizes | kFSCatInfoRsrcSizes, &fileInfo, NULL, NULL, NULL);
		
		if (err == noErr) {
			resourceForkSize = fileInfo.rsrcLogicalSize;
			dataForkSize = fileInfo.dataLogicalSize;
		}
	}
	
	if (itemExists && aFork == MDAnyFork) {
		if (resourceForkSize) {
			aFork = MDResourceFork;
		} else if (dataForkSize) {
			aFork = MDDataFork;
		} else {
			aFork = MDResourceFork;
		}
	} else if (!itemExists && aFork == MDAnyFork) {
		aFork = MDResourceFork;
	}
	
	fork = aFork;
	permission = aPermission;
	
	HFSUniStr255	forkName;
	
	if (fork == MDResourceFork) {
		err = FSGetResourceForkName(&forkName);
	} else {
		err = FSGetDataForkName(&forkName);
	}
	
	if (err != noErr) {
		NSLog(@"[%@ %@] %@ returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aFork == MDResourceFork ? @"FSGetResourceForkName()" : @"FSGetDataForkName()"), err);
		[self release];
		return nil;
	}
	
	if (itemExists && ((fork == MDResourceFork && resourceForkSize) || (fork == MDDataFork && dataForkSize))) {
		if (![filePath getFSRef:&fileRef error:outError]) {
			[self release];
			return nil;
		}
		
		Boolean sane = NO;
		
		err = MDCheckResourceFileSanity(&fileRef, &forkName, &sane);
		
		if (sane == NO) {
			
			NSLog(@"[%@ %@] the resource file at '%@' wasn't sane; MDCheckResourceFileSanity() returned err == %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [aURL path], err);
			
			NSLog(@"[%@ %@] ERROR: file appears to be a corrupt %@ and will not be opened...", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (aFork == MDResourceFork ? @"resource file" : @"datafork-based resource file"));
			if (outError) *outError = [NSError errorWithDomain:MDResourceFileErrorDomain code:MDResourceFileCorruptResourceFileError userInfo:nil];
			[self release];
			return nil;
		}
	}
	
	if ((self = [super init])) {
		
		FSRef			parentRef;
		
		UniChar			fileNameUnicode[255];
		UniCharCount	fileNameLength;
		NSString		*fileName;
		
		
		/*
		 fsCurPerm		= 0x00,
		 fsRdPerm		= 0x01,
		 fsWrPerm		= 0x02,
		 fsRdWrPerm		= 0x03,
		 fsRdWrShPerm	= 0x04
		 
		 To determine if I have write permission, I can't do		// ??????
		 if (permission & fsRdWrPerm) 
		 
		 */
		
		if (permission == MDReadWritePermission ||
			permission == MDCurrentAllowablePermission) {
			
			if (![[[aURL path] stringByDeletingLastPathComponent] getFSRef:&parentRef error:outError]) {
				NSLog(@"[%@ %@] (%@) getFSRef: for parentRef failed", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [aURL path]);
				[self release];
				return nil;
			}
			
			fileName = [[aURL path] lastPathComponent];
			fileNameLength = [fileName length];
			
			if (fileNameLength > NAME_MAX) {
				NSLog(@"[%@ %@] fileNameLength > NAME_MAX!; aborting...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				[self release];
				return nil;
			}
			
			// if a POSIX path name coming in has a slash / in the actual file name, it'll have been converted to a colon : by POSIX. This command needs a colon-delimited path, so it needs to be converted from colons back to slashes
			
			fileName = [fileName colonToSlash];
			
			[fileName getCharacters:fileNameUnicode range:NSMakeRange(0, fileNameLength)];
			
			err = FSCreateResourceFile(&parentRef,
									   fileNameLength,
									   fileNameUnicode,
									   kFSCatInfoNone,
									   NULL,
									   forkName.length,
									   forkName.unicode,
									   &fileRef,
									   NULL);
			
			if (err == noErr || err == dupFNErr) {
				
				err = FSOpenResourceFile(&fileRef, forkName.length, forkName.unicode, permission, &fileReference);
				
				if (!(fileReference > 0 && err == noErr)) {
					NSLog(@"[%@ %@] (%@) an error (%hi) occurred while trying to open the resource file", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [aURL path], err);
					
					if (err == permErr) {
						NSLog(@"[%@ %@] unable to open resource file with Read-Write access, will retry with Read-Only access...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
						
						permission = MDReadPermission;
						
						err = FSOpenResourceFile(&fileRef, forkName.length, forkName.unicode, permission, &fileReference);
						
						if (!(fileReference > 0 && err == noErr)) {
							NSLog(@"[%@ %@] tried opening resource file with Read-Only access, but an error (%hi) still occurred while trying to open the resource file!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
							[self release];
							return nil;
						}
						
					}
				}
			}
			
		} else {   // don't have write permission
			
			err = FSOpenResourceFile(&fileRef, forkName.length, forkName.unicode, permission, &fileReference);
			
			if ( !(fileReference > 0 && err == noErr)) {
				NSLog(@"[%@ %@] an error (%hi) occurred while trying to open the resource fork!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
				[self release];
				return nil;
			}
		}
		
		ResourceCount numberOfTypes = Count1Types();
		
		for (ResourceIndex typeIndex = 1; typeIndex <= numberOfTypes; typeIndex++) {
			ResType resType = 0;
			
			Get1IndType(&resType, typeIndex);
			
			if (ResError() == noErr) {
				if (resType == 'plst') {
					plistResource = [[MDResource resourceWithType:'plst' index:1 error:outError] retain];
				} else if (resType == 'icns') {
					customIconResource = [[MDResource resourceWithType:'icns' index:1 error:outError] retain];
				}
			}
		}
	}
	return self;
}


- (void)dealloc {
	if (fileReference > 0) CloseResFile(fileReference);
	[filePath release];
	[plistResource release];
	[customIconResource release];
	[super dealloc];
}


- (ResFileRefNum)fileReference {
    return fileReference;
}

- (NSString *)filePath {
    return filePath;
}

- (MDFork)fork {
    return fork;
}

- (MDPermission)permission {
    return permission;
}

- (MDResource *)plistResource {
    return plistResource;
}


- (MDResource *)customIconResource {
    return customIconResource;
}


- (BOOL)addResource:(MDResource *)aResource error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (permission == MDReadPermission) return NO;
	if (aResource == nil) return NO;
	if (outError) *outError = nil;
	
	if (![self addData:[aResource resourceData]
		  resourceType:[aResource resourceType]
			resourceID:[aResource resourceID]
		  resourceName:[aResource resourceName]
				error:outError]) {
		return NO;
	}
	return [self saveChanges:outError];
}


- (BOOL)removeResource:(MDResource *)aResource error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (permission == MDReadPermission) return NO;
	if (aResource == nil) return NO;
	if (outError) *outError = nil;
	
	if (![self removeDataForResourceType:[aResource resourceType] resourceID:[aResource resourceID] error:outError]) {
		return NO;
	}
	return [self saveChanges:outError];
}



- (void)closeResourceFile {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (fileReference > 0) CloseResFile(fileReference);
	fileReference = 0;
}


- (BOOL)saveChanges:(NSError **)localOutError {
	OSErr err = noErr;
	UpdateResFile(fileReference);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: UpdateResFile() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return NO;
	}
	return YES;
}


- (NSData *)dataForResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)localOutError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	OSErr err = noErr;
	ResFileRefNum prevRefNumber = CurResFile();
	UseResFile(fileReference);
	NSData *data = nil;
	
	Handle resHandle = Get1Resource(aType, anID);
	err = ResError();
	if ( !(err == noErr && resHandle)) {
		NSLog(@"[%@ %@] ERROR: Get1Resource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return nil;
	}
	
	HLock(resHandle);
	data = [NSData dataWithBytes:*resHandle length:GetHandleSize(resHandle)];
	HUnlock(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: GetHandleSize() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		UseResFile(prevRefNumber);
		return nil;
	}
	
	ReleaseResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ReleaseResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return nil;
	}
	
	UseResFile(prevRefNumber);
	return data;
}


- (BOOL)setAttributeFlags:(ResAttributes)attributes forResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)localOutError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	OSErr err = noErr;
	ResFileRefNum prevRefNumber = CurResFile();
	
	UseResFile(fileReference);
	
	Handle resHandle = Get1Resource(aType, anID);
	err = ResError();
	if ( !(err == noErr && resHandle)) {
		NSLog(@"[%@ %@] ERROR: Get1Resource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return NO;
	}
	
	SetResAttrs(resHandle, attributes);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: SetResAttrs() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		UseResFile(prevRefNumber);
		return NO;
	}
	
	ChangedResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ChangedResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		UseResFile(prevRefNumber);
		return NO;
	}
	
	ReleaseResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ReleaseResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return NO;
	}
	
	UseResFile(prevRefNumber);
	err = ResError();
	
	return (err == noErr);
}



- (BOOL)addData:(NSData *)aData resourceType:(ResType)aType resourceID:(ResID)anID resourceName:(NSString *)aName error:(NSError **)localOutError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (![self removeDataForResourceType:aType resourceID:anID error:localOutError]) {
		return NO;
	}
	
	Handle resHandle = NULL;
	OSErr err = noErr;
	
	err = PtrToHand([aData bytes], &resHandle, [aData length]);
	if ( !(err == noErr && resHandle)) {
		NSLog(@"[%@ %@] ERROR: PtrToHand() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return NO;
	}
	
	ResFileRefNum prevRefNumber = CurResFile();
	UseResFile(fileReference);
	
	Str255 pascalName = "\p";
	
	if (aName) {
		if (!CFStringGetPascalString((CFStringRef)aName, pascalName, sizeof(pascalName), kCFStringEncodingMacRoman)) {
			NSLog(@"[%@ %@] *** ERROR: CFStringGetPascalString() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
	}
	
	HLock(resHandle);
	AddResource(resHandle, aType, anID, pascalName);
	HUnlock(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: AddResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		UseResFile(prevRefNumber);
		return NO;
	}
	
	ReleaseResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: ReleaseResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return NO;
	}
	
	UseResFile(prevRefNumber);
	err = ResError();
	return (err == noErr);
}


- (BOOL)removeDataForResourceType:(ResType)aType resourceID:(ResID)anID error:(NSError **)localOutError {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	OSErr err = noErr;
	ResFileRefNum prevRefNumber = CurResFile();
	UseResFile(fileReference);
	
	Handle resHandle = Get1Resource(aType, anID);
	err = ResError();
	if (err == noErr && resHandle == NULL) {
		UseResFile(prevRefNumber);
		return YES;
	} else if ( !(err == noErr && resHandle)) {
		NSLog(@"[%@ %@] ERROR: Get1Resource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		UseResFile(prevRefNumber);
		return NO;
	}
	
	RemoveResource(resHandle);
	err = ResError();
	if (err != noErr) {
		NSLog(@"[%@ %@] ERROR: RemoveResource() returned %hi", NSStringFromClass([self class]), NSStringFromSelector(_cmd), err);
		if (localOutError) *localOutError = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		ReleaseResource(resHandle);
		UseResFile(prevRefNumber);
		return NO;
	}
	
	// The docs say:
	
	/* "The RemoveResource function does not dispose of the handle you pass into it; to 
	 do so you must call the Memory Manager function DisposeHandle after calling RemoveResource.
	 You should dispose the handle if you want to release the memory before updating or closing the resource fork" */
	
	// However, calling DisposeHandle() causes a crash. ReleaseResource() is also not appropriate since it will return resNotFound.
	
	UseResFile(prevRefNumber);
	err = ResError();
	return (err == noErr);
}


@end







