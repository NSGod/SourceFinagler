#include <CoreServices/CoreServices.h>
#import <Cocoa/Cocoa.h>
#import <NVTextureTools/NVTextureTools.h>
#import <VTF/VTF.h>
#import <TextureKit/TextureKit.h>


#ifdef __cplusplus
extern "C" {
#endif

	
#define MD_DEBUG 0
	
	
BOOL MDGetMetadataFromImageWithContentsOfFile(NSString *filePath, NSString *contentTypeUTI, NSMutableDictionary *attributes, NSError **error);


Boolean GetMetadataForURL(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFURLRef url) {
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (![(NSString *)contentTypeUTI isEqualToString:TKVTFType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKDDSType] &&
		![(NSString *)contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		NSLog(@"Source.mdimporter; GetMetadataForFile(): contentTypeUTI != vtf or dds or sfti; (contentTypeUTI == %@)", contentTypeUTI);
		[pool release];
		return FALSE;
	}
	
#if MD_DEBUG
	NSLog(@"Source.mdimporter; GetMetadataForURL() file == %@", [(NSURL *)url path]);
#endif
	
	BOOL result = MDGetMetadataFromImageWithContentsOfFile([(NSURL *)url path], (NSString *)contentTypeUTI, (NSMutableDictionary *)attributes, NULL);
	
	[pool release];
	return (Boolean)result;
}

	
using namespace VTFLib;
using namespace nv;
	
BOOL MDGetMetadataFromImageWithContentsOfFile(NSString *filePath, NSString *contentTypeUTI, NSMutableDictionary *attributes, NSError **error) {
	if (attributes == nil || filePath == nil || contentTypeUTI == nil) return NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
	
	if (data == nil) {
		NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): data == nil for filePath == %@", filePath);
		[pool release];
		return NO;
	}
	
	if ([data length] < sizeof(OSType)) {
		NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): [data length] < 4 for filePath == %@", filePath);
		[data release];
		[pool release];
		return NO;
	}
	
	OSType magic = 0;
	[data getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	
	if ([contentTypeUTI isEqualToString:TKSFTextureImageType]) {
		
		TKImage *sfti = [[TKImage alloc] initWithData:data firstRepresentationOnly:NO];
		
		if (sfti == nil) {
			NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): failed to create a TKImage for file at %@!", filePath);
			[data release];
			[pool release];
			return NO;
		}
		
		NSSize imageSize = [sfti size];
		
		[attributes setObject:[NSNumber numberWithBool:[sfti hasAlpha]] forKey:(id)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:[sfti hasMipmaps]] forKey:@"com_markdouma_image_mipmaps"];
		[attributes setObject:[NSNumber numberWithBool:[sfti isAnimated]] forKey:@"com_markdouma_image_animated"];
		
		[attributes setObject:[NSNumber numberWithBool:([sfti isCubemap] || [sfti isSpheremap])] forKey:@"com_markdouma_image_environment_map"];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.width] forKey:(id)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.height] forKey:(id)kMDItemPixelHeight];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:imageSize.width * imageSize.height] forKey:(id)kMDItemPixelCount];
		
		[sfti release];
		[data release];
		[pool release];
		
		return YES;
		
		
	} else if ([contentTypeUTI isEqualToString:TKVTFType]) {
		
		if (magic == TKHTMLErrorMagic) {
			NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file at fileURL \"%@\" appears to be an ERROR 404 HTML file rather than a valid VTF", filePath);
			[data release];
			[pool release];
			return NO;
		}
		
		CVTFFile *file = new CVTFFile();
		
		if (file == 0) {
			NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): CVTFFile() returned NULL (for %@)", filePath);
			[data release];
			[pool release];
			return NO;
		}
		
		if ( file->Load([data bytes], [data length], vlTrue) == NO) {
			if (magic == TKVTFMagic) {
				NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file->Load() (for %@) failed!", filePath);
			} else {
				NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file->Load() (for %@) failed! (does not appear to be a valid VTF; magic == 0x%x, %@)", filePath, (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
			}
			delete file;
			[data release];
			[pool release];
			return NO;
		}
		
		BOOL isEnvironmentMap = (file->GetFaceCount() > 1);
		
		BOOL hasAlphaChannel = file->GetFlags() & (TEXTUREFLAGS_ONEBITALPHA | TEXTUREFLAGS_EIGHTBITALPHA);
		BOOL hasMipmaps = (file->GetMipmapCount() > 1);
		BOOL isAnimated = (file->GetFrameCount() > 1);
		NSString *theCompression = nil;
		SVTFImageFormatInfo imageFormatInfo = file->GetImageFormatInfo(file->GetFormat());
		if (imageFormatInfo.lpName != NULL) {
			theCompression = [NSString stringWithFormat:@"%s", imageFormatInfo.lpName];
		}
		NSUInteger theWidth = file->GetWidth();
		NSUInteger theHeight = file->GetHeight();
		NSString *theVersion = [NSString stringWithFormat:@"%u.%u", file->GetMajorVersion(), file->GetMinorVersion()];
		
		[attributes setObject:[NSNumber numberWithBool:hasAlphaChannel] forKey:(NSString *)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:hasMipmaps] forKey:@"com_markdouma_image_mipmaps"];
		[attributes setObject:[NSNumber numberWithBool:isAnimated] forKey:@"com_markdouma_image_animated"];
		
		// only set environment mask if it's true?
		[attributes setObject:[NSNumber numberWithBool:isEnvironmentMap] forKey:@"com_markdouma_image_environment_map"];
		
		[attributes setObject:[NSNumber numberWithUnsignedInteger:theWidth] forKey:(NSString *)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:theHeight] forKey:(NSString *)kMDItemPixelHeight];
		if (theVersion) [attributes setObject:theVersion forKey:(NSString *)kMDItemVersion];
		if (theCompression) [attributes setObject:theCompression forKey:@"com_markdouma_image_compression"];
		
		delete file;
		[data release];
		[pool release];
		return YES;
		
		
	} else if ([contentTypeUTI isEqualToString:TKDDSType]) {
		
		if (magic != TKDDSMagic) {
			NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file at filePath \"%@\" does not appear to be a valid DDS; magic == 0x%x, %@", filePath, (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
			[data release];
			[pool release];
			return NO;
		}
		
		DirectDrawSurface *dds = new DirectDrawSurface((unsigned char *)[data bytes], [data length]);
		if (!dds->isValid() || !dds->isSupported() || (dds->width() > 65535 || (dds->height() > 65535))) {
			if (!dds->isValid()) {
				NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file at filePath \"%@\": dds image is not valid, info follows:", filePath);
			} else if (!dds->isSupported()) {
				NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file at filePath \"%@\": dds image format is not supported, info follows:", filePath);
			} else {
				NSLog(@"MDGetMetadataFromImageWithContentsOfFile(): file at filePath \"%@\": dds image dimensions are too large, info follows:", filePath);
			}
			dds->printInfo();
			delete dds;
			[data release];
			[pool release];
			return NO;
		}
		
#if MD_DEBUG
//		dds->printInfo();
#endif
		
		BOOL hasAlphaChannel = dds->hasAlpha();
		BOOL hasMipmaps = (dds->mipmapCount() > 1);
		BOOL isEnvironmentMap = dds->isTextureCube();
		
		NSString *theCompression = nil;
		const char *compression = NULL;
		compression = dds->d3d9FormatString();
		if (compression) {
			theCompression = [NSString stringWithFormat:@"%s", compression];
		}
		
		NSUInteger theWidth = dds->width();
		NSUInteger theHeight = dds->height();
		
		[attributes setObject:[NSNumber numberWithBool:hasAlphaChannel] forKey:(NSString *)kMDItemHasAlphaChannel];
		[attributes setObject:[NSNumber numberWithBool:hasMipmaps] forKey:@"com_markdouma_image_mipmaps"];
		
		// only set environment mask if it's true?
		[attributes setObject:[NSNumber numberWithBool:isEnvironmentMap] forKey:@"com_markdouma_image_environment_map"];
		
		[attributes setObject:[NSNumber numberWithUnsignedInteger:theWidth] forKey:(NSString *)kMDItemPixelWidth];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:theHeight] forKey:(NSString *)kMDItemPixelHeight];
		[attributes setObject:[NSNumber numberWithUnsignedInteger:theWidth * theHeight] forKey:(id)kMDItemPixelCount];
		if (theCompression) [attributes setObject:theCompression forKey:@"com_markdouma_image_compression"];
		
		[data release];
		[pool release];
		return YES;
		
	}
	
	[data release];
	[pool release];
	return NO;
}
	
	
	

#ifdef __cplusplus
}
#endif


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



