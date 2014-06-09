#include <CoreServices/CoreServices.h>
#import <Cocoa/Cocoa.h>
#import <NVTextureTools/NVTextureTools.h>
#import <VTF/VTF.h>
#import <TextureKit/TextureKit.h>
#import "TKPrivateInterfaces.h"
#import "TKPrivateCPPInterfaces.h"
#import "TKFoundationAdditions.h"


#ifdef __cplusplus
extern "C" {
#endif
	
static NSString * const MDBundleIdentifierKey = @"com.markdouma.mdimporter.Source";
	
Boolean GetMetadataForURL(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFURLRef url);
	
BOOL MDGetMetadataFromImageAtPath(NSString *filePath, NSString *contentTypeUTI, NSMutableDictionary *attributes, NSError **error);

	
#ifdef __cplusplus
}
#endif


#define MD_DEBUG 1

	

Boolean GetMetadataForURL(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFURLRef url) {
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![(NSString *)contentTypeUTI isEqualToString:TKVTFType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		NSLog(@"%@; %s(): contentTypeUTI != vtf or dds or sfti; (contentTypeUTI == \"%@\")", MDBundleIdentifierKey, __FUNCTION__, contentTypeUTI);
		[pool release];
		return FALSE;
	}
	
#if MD_DEBUG
	NSLog(@"%@; %s(): file == \"%@\"", MDBundleIdentifierKey, __FUNCTION__, [(NSURL *)url path]);
//	printf("printf() test\n");
//	fprintf(stderr, "%s; %s(): fprintf() test\n", [MDBundleIdentifierKey fileSystemRepresentation], __FUNCTION__);
#endif
	
	BOOL result = MDGetMetadataFromImageAtPath([(NSURL *)url path], (NSString *)contentTypeUTI, (NSMutableDictionary *)attributes, NULL);
	
	[pool release];
	return (Boolean)result;
}

	
using namespace VTFLib;
using namespace nv;
	
	
BOOL MDGetMetadataFromImageAtPath(NSString *filePath, NSString *contentTypeUTI, NSMutableDictionary *attributes, NSError **error) {
	if (attributes == nil || filePath == nil || contentTypeUTI == nil) return NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
	
	if (data == nil) {
		NSLog(@"%@; %s(): data == nil for \"%@\")", MDBundleIdentifierKey, __FUNCTION__, filePath);
		[pool release];
		return NO;
	}
	
	if ([data length] < sizeof(OSType)) {
		NSLog(@"%@; %s(): [data length] < 4 for \"%@\")", MDBundleIdentifierKey, __FUNCTION__, filePath);
		[data release];
		[pool release];
		return NO;
	}
	
	OSType magic = 0;
	[data getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	
	if ([contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		TKImage *sfti = [[TKImage alloc] initWithData:data firstRepresentationOnly:NO error:error];
		
		if (sfti == nil) {
			NSLog(@"%@; %s(): failed to create a TKImage for file at \"%@\"!", MDBundleIdentifierKey, __FUNCTION__, filePath);
			[data release];
			[pool release];
			return NO;
		}
		
		NSSize imageSize = [sfti size];
		
		[attributes setObject:[NSNumber numberWithBool:[sfti hasAlpha]] forKey:(id)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:[sfti hasMipmaps]] forKey:@"com_markdouma_image_mipmaps"];
		[attributes setObject:[NSNumber numberWithBool:[sfti isAnimated]] forKey:@"com_markdouma_image_animated"];
		
		[attributes setObject:[NSNumber numberWithBool:[sfti isEnvironmentMap]] forKey:@"com_markdouma_image_environment_map"];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.width] forKey:(id)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.height] forKey:(id)kMDItemPixelHeight];
		
		// `kMDItemPixelCount` is only available in OS X 10.6 and later
		if (TKGetSystemVersion() >= TKSnowLeopard) {
			[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.width * imageSize.height] forKey:(id)kMDItemPixelCount];
		}
		
		[sfti release];
		[data release];
		[pool release];
		
		return YES;
		
		
	} else if ([contentTypeUTI isEqualToString:TKVTFType]) {
		
		if (magic == TKHTMLErrorMagic) {
			NSLog(@"%@; %s(): file at \"%@\" appears to be an ERROR 404 HTML file rather than a valid VTF", MDBundleIdentifierKey, __FUNCTION__, filePath);
			[data release];
			[pool release];
			return NO;
		}
		
		CVTFFile file;
		
		if (file.Load([data bytes], [data length], vlTrue) == NO) {
			if (magic == TKVTFMagic) {
				NSLog(@"%@; %s(): file.Load() failed for file at \"%@\"! vlGetLastError() == %s", MDBundleIdentifierKey, __FUNCTION__, filePath, vlGetLastError());
			} else {
				NSLog(@"%@; %s(): file.Load() failed for file at \"%@\"! Does not appear to be a valid VTF; magic == 0x%x, %@; vlGetLastError() == %s", MDBundleIdentifierKey, __FUNCTION__, filePath, (unsigned int)magic, NSFileTypeForHFSTypeCode(magic), vlGetLastError());
			}
			[data release];
			[pool release];
			return NO;
		}
		
		NSString *formatName = [TKVTFImageRep localizedNameOfVTFImageFormat:file.GetFormat()];
		if (formatName) [attributes setObject:formatName forKey:@"com_markdouma_image_compression"];
		
		[attributes setObject:[NSNumber numberWithBool:((file.GetFlags() & TEXTUREFLAGS_ONEBITALPHA) || (file.GetFlags() & TEXTUREFLAGS_EIGHTBITALPHA))] forKey:(NSString *)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:(file.GetMipmapCount() > 1)] forKey:@"com_markdouma_image_mipmaps"];
		[attributes setObject:[NSNumber numberWithBool:(file.GetFrameCount() > 1)] forKey:@"com_markdouma_image_animated"];
		
		// only set environment mask if it's true?
		[attributes setObject:[NSNumber numberWithBool:(file.GetFaceCount() > 1)] forKey:@"com_markdouma_image_environment_map"];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:file.GetWidth()] forKey:(NSString *)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:file.GetHeight()] forKey:(NSString *)kMDItemPixelHeight];
		
		// `kMDItemPixelCount` is only available in OS X 10.6 and later
		if (TKGetSystemVersion() >= TKSnowLeopard) {
			[attributes setObject:[NSNumber numberWithUnsignedInteger:file.GetWidth() * file.GetHeight()] forKey:(NSString *)kMDItemPixelCount];
		}
		
		[attributes setObject:[NSString stringWithFormat:@"%u.%u", file.GetMajorVersion(), file.GetMinorVersion()] forKey:(NSString *)kMDItemVersion];
		
		[data release];
		[pool release];
		return YES;
		
		
	} else if ([contentTypeUTI isEqualToString:TKDDSType]) {
		
		if (magic != TKDDSMagic) {
			NSLog(@"%@; %s(): file at \"%@\"does not appear to be a valid DDS; magic == 0x%x, %@", MDBundleIdentifierKey, __FUNCTION__, filePath, (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
			[data release];
			[pool release];
			return NO;
		}
		
		DirectDrawSurface dds((unsigned char *)[data bytes], [data length]);
		
		if (!dds.isValid()) {
			NSLog(@"%@; %s(): file at \"%@\": dds image is not valid, info follows:", MDBundleIdentifierKey, __FUNCTION__, filePath);
			dds.printInfo();
			[data release];
			[pool release];
			return NO;
		}
		
#if MD_DEBUG
//		dds.printInfo();
#endif
		
		NSString *formatName = nil;
		
		if (dds.header.hasDX10Header()) {
			formatName = [TKDDSImageRep localizedNameOfDX10Format:(DXGI_FORMAT)dds.header.header10.dxgiFormat];
		} else {
			formatName = [TKDDSImageRep localizedNameOfDX9Format:(D3DFORMAT)dds.header.d3d9Format()];
		}
		if (formatName) [attributes setObject:formatName forKey:@"com_markdouma_image_compression"];
		
		[attributes setObject:[NSNumber numberWithBool:dds.hasAlpha()] forKey:(NSString *)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:(dds.mipmapCount() > 1)] forKey:@"com_markdouma_image_mipmaps"];
		
		[attributes setObject:[NSNumber numberWithBool:dds.header.hasDX10Header()] forKey:@"com_markdouma_image_dds_dx_ten_header"];
		
		// only set environment mask if it's true?
		[attributes setObject:[NSNumber numberWithBool:dds.isTextureCube()] forKey:@"com_markdouma_image_environment_map"];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:dds.width()] forKey:(NSString *)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:dds.height()] forKey:(NSString *)kMDItemPixelHeight];
		
		// `kMDItemPixelCount` is only available in OS X 10.6 and later
		if (TKGetSystemVersion() >= TKSnowLeopard) {
			[attributes setObject:[NSNumber numberWithUnsignedInteger:dds.width() * dds.height()] forKey:(id)kMDItemPixelCount];
		}
		
		[data release];
		[pool release];
		return YES;
		
	}
	
	[data release];
	[pool release];
	return NO;
}


/* -----------------------------------------------------------------------------
 Step 1
 Set the UTI types the importer supports
 
 Modify the CFBundleDocumentTypes entry in Info.plist to contain
 an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
 that your importer can handle
 
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 2 
 Implement the GetMetadataForURL function
 
 Implement the GetMetadataForURL function below to scrape the relevant
 metadata from your document and return it as a CFDictionary using standard keys
 (defined in MDItem.h) whenever possible.
 ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
 Step 3 (optional) 
 If you have defined new attributes, update schema.xml and schema.strings files
 
 The schema.xml should be added whenever you need attributes displayed in 
 Finder's get info panel, or when you have custom attributes.  
 The schema.strings should be added whenever you have custom attributes. 
 
 Edit the schema.xml file to include the metadata keys that your importer returns.
 Add them to the <allattrs> and <displayattrs> elements.
 
 Add any custom types that your importer requires to the <attributes> element
 
 <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
 
 ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
 Get metadata attributes from file
 
 This function's job is to extract useful information your file format supports
 and return it as a dictionary
 ----------------------------------------------------------------------------- */



