//
//  TKDocumentController.m
//  Texture Kit
//
//  Created by Mark Douma on 3/16/2009.
//  Copyright (c) 2009-2012 Mark Douma. All rights reserved.
//

#import "TKDocumentController.h"
#import <TextureKit/TextureKit.h>

#import "TKImageDocument.h"

#import <CoreServices/CoreServices.h>

//#import "TKFoundationAdditions.h"
#import "MDFoundationAdditions.h"



#define TK_DEBUG 1

static NSMutableDictionary *nativeImageTypeIdentifiersAndDisplayNames = nil;

static NSSet *nonImageUTTypes = nil;

NSString * const TKApplicationBundleIdentifier = @"com.markdouma.SourceFinagler";


@implementation TKDocumentController


+ (void)initialize {
	if (nonImageUTTypes == nil) {
		if (nativeImageTypeIdentifiersAndDisplayNames == nil) nativeImageTypeIdentifiersAndDisplayNames = [[NSMutableDictionary alloc] init];
		
		NSMutableArray *supportedDocTypes = [NSMutableArray array];
		NSArray *docTypes = [[NSBundle bundleWithIdentifier:TKApplicationBundleIdentifier] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
//		NSLog(@"[%@ %@] docTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), docTypes);
	
		for (NSDictionary *docType in docTypes) {
			NSString *docClass = [docType objectForKey:@"NSDocumentClass"];
			if (docClass) {
				NSArray *contentTypes = [docType objectForKey:@"LSItemContentTypes"];
				if (contentTypes && [contentTypes count]) {
					NSString *utiType = [contentTypes objectAtIndex:0];
					if (![utiType isEqualToString:(NSString *)kUTTypeImage]) {
						[supportedDocTypes addObject:utiType];
						if ([docClass isEqualToString:@"TKImageDocument"]) {
							NSString *displayName = [docType objectForKey:@"CFBundleTypeName"];
							if (displayName) {
								[nativeImageTypeIdentifiersAndDisplayNames setObject:displayName forKey:utiType];
							}
						}
					}
				}
			}
		}
		nonImageUTTypes = [[NSSet setWithArray:supportedDocTypes] retain];
	}
	
}



// Return the names of NSDocument subclasses supported by this application.
// In this app, the only class is "ImageDoc".
//
- (NSArray *)documentClassNames {
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	static NSArray *documentClassNames = nil;
	if (documentClassNames == nil) {
		documentClassNames = [[NSArray arrayWithObjects:
							   @"TKImageDocument",
							   @"MDGCFDocument",
							   @"MDBSPDocument",
							   @"MDNCFDocument",
							   @"MDPAKDocument",
							   @"MDVPKDocument",
							   @"MDWADDocument",
							   @"MDSGADocument",
							   @"MDXZPDocument", nil] retain];
	}
	return documentClassNames;
}


// Return the name of the document type that should be used when opening a URL
// • For ImageIO images: "In this app, we return the UTI type returned by CGImageSourceGetType."

- (NSString *)typeForContentsOfURL:(NSURL *)absURL error:(NSError **)outError {
//	NSLog(@"[%@ %@] absURL == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), absURL);
	
    NSString *documentUTType = nil;
	
	FSRef itemRef;
	
	if (![[absURL path] getFSRef:&itemRef error:outError]) {
		return nil;
	}
	
	OSStatus status = noErr;
	NSString *utiType = nil;
	
	CFTypeRef typeRef = NULL;
	
	status = LSCopyItemAttribute(&itemRef, kLSRolesAll, kLSItemContentType, &typeRef);
	
	if (status != noErr) {
		if (typeRef) CFRelease(typeRef);
		return nil;
	}
	
	if (CFGetTypeID(typeRef) == CFStringGetTypeID()) utiType = (NSString *)typeRef;
//	NSLog(@"[%@ %@] LSCopyItemAttribute()'s utiType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), utiType);
	
	if ([[NSWorkspace sharedWorkspace] type:utiType conformsToType:(NSString *)kUTTypeImage] &&
		![utiType isEqualToString:TKVTFType] &&
		![utiType isEqualToString:TKDDSType] &&
		![utiType isEqualToString:TKSFTextureImageType]) {
		// file in question is a generic image, let ImageIO handle it
		
		CGImageSourceRef isrc = CGImageSourceCreateWithURL((CFURLRef)absURL, NULL);
		if (isrc) {
			documentUTType = [[(NSString *)CGImageSourceGetType(isrc) retain] autorelease];
			CFRelease(isrc);
			CFRelease(typeRef);
//			NSLog(@"[%@ %@] CGImageSourceGetType()'s documentUTType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), documentUTType);
			return documentUTType;
		}
	}
	// otherwise, file is one we handle, so let super handle it
	documentUTType = [super typeForContentsOfURL:absURL error:outError];
//	NSLog(@"[%@ %@] super's typeForContentsOfURL:error: == documentUTType == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), documentUTType);
	
	CFRelease(typeRef);
	
	return documentUTType;
}


// Given a document type name, return the subclass of NSDocument
// that should be instantiated when opening a document of that type.
// In this app, the only class is "ImageDoc".
//
- (Class)documentClassForType:(NSString *)typeName {
//	NSLog(@"[%@ %@] type == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
	
	if ([nonImageUTTypes containsObject:typeName]) {
		return [super documentClassForType:typeName];
	}
    return [[NSBundle mainBundle] classNamed:@"TKImageDocument"];
}


// Given a document type name, return a string describing the document 
// type that is fit to present to the user.
//
- (NSString *)displayNameForType:(NSString *)typeName {
//	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
	
	if ([nonImageUTTypes containsObject:typeName]) {
//		NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
		NSString *displayName = [super displayNameForType:typeName];
		if (displayName == nil) {
			NSLog(@"[%@ %@] displayName == nil!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			displayName = [nativeImageTypeIdentifiersAndDisplayNames objectForKey:typeName];
			return displayName;
		}
		return [super displayNameForType:typeName];
	}
    return TKImageIOLocalizedString(typeName);
}


// Given a document type, return an array of corresponding file name extensions 
// and HFS file type strings of the sort returned by NSFileTypeForHFSTypeCode().
// In this app, 'typeName' is a UTI type so we can call UTTypeCopyDeclaration().
//
- (NSArray *)fileExtensionsFromType:(NSString *)typeName {
//	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
	
    NSArray *readExts = nil;
	
	NSDictionary *utiDeclarations = [(NSDictionary *)UTTypeCopyDeclaration((CFStringRef)typeName) autorelease];
	NSDictionary *utiSpec = [utiDeclarations objectForKey:(NSString *)kUTTypeTagSpecificationKey];
	if (utiSpec) {
		id extensions = [utiSpec objectForKey:(NSString *)kUTTagClassFilenameExtension];
		if ([extensions isKindOfClass:[NSString class]]) {
			readExts = [NSArray arrayWithObject:extensions];
		} else if ([extensions isKindOfClass:[NSArray class]]) {
			readExts = [NSArray arrayWithArray:extensions];
		}
	}
    
    return readExts;
}



@end


