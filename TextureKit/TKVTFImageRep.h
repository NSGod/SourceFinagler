//
//  TKVTFImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>

//	Reference: http://developer.valvesoftware.com/wiki/Valve_Texture_Format
//  
//	NOTE: "Bluescreen" Alpha uses any pixel with a pixel of R0, G0, B255 as transparent.

enum {
	
	TKVTFNoFormat				= 0,
	
	TKVTFFormatDXT1				= 1,	//  4 bpp
	TKVTFFormatDXT1a			= 2,	//  4 bpp - DXT1 with 1-bit Alpha
	TKVTFFormatDXT3				= 3,	//  8 bpp
	TKVTFFormatDXT5				= 4,	//  8 bpp
	
	TKVTFFormatI				= 5,	//  8 bpp - Luminance
	TKVTFFormatIA				= 6,	// 16 bpp - Luminance, Alpha
	TKVTFFormatP				= 7,	//  8 bpp - Paletted	/**    NOT SUPPORTED    **/
	TKVTFFormatA				= 8,	//  8 bpp - Alpha
	
	TKVTFFormatRGB565			= 9,	// 16 bpp
	TKVTFFormatBGR565			= 10,	// 16 bpp
	
	TKVTFFormatBGRA5551			= 11,	// 16 bpp
	TKVTFFormatBGRA4444			= 12,	// 16 bpp
	TKVTFFormatBGRX5551			= 13,	// 16 bpp - Blue, Green, Red, Unused 
	
	TKVTFFormatRGB				= 14,	// 24 bpp
	TKVTFFormatARGB				= 15,	// 32 bpp
	TKVTFFormatRGBA				= 16,	// 32 bpp
	
	TKVTFFormatBGR				= 17,	// 24 bpp
	TKVTFFormatBGRA				= 18,	// 32 bpp
	TKVTFFormatABGR				= 19,	// 32 bpp
	TKVTFFormatBGRX				= 20,	// 32 bpp
	
	TKVTFFormatBluescreenRGB	= 21,	// 24 bpp - Red, Green, Blue, "BlueScreen" Alpha
	TKVTFFormatBluescreenBGR	= 22,	// 32 bpp
	
	TKVTFFormatRGBA16161616		= 23,	// 64 bpp - integer HDR format
	TKVTFFormatRGBA16161616F	= 24,	// 64 bpp - floating point HDR format
	
	TKVTFFormatR32F				= 25,	// 32 bpp - Luminance
	TKVTFFormatRGB323232F		= 26,	// 96 bpp
	TKVTFFormatRGBA32323232F	= 27,	// 128 bpp
	
	TKVTFFormatUV				= 28,	// 16 bpp - 2 channel format for DuDv/Normal maps
	TKVTFFormatUVWQ				= 29,	// 32 bpp - 4 channel format for DuDv/Normal maps
	TKVTFFormatUVLX				= 30,	// 32 bpp - 4 channel format for DuDv/Normal maps
	
	
	/**    NOT SUPPORTED below this point  **/
	
	// Depth-stencil texture formats for shadow depth mapping
	
	TKVTFFormatNVDST16			= 31,	/**    NOT SUPPORTED    **/
	TKVTFFormatNVDST24			= 32,	/**    NOT SUPPORTED    **/
	TKVTFFormatNVINTZ			= 33,	/**    NOT SUPPORTED    **/		// Vendor-specific depth-stencil texture
	TKVTFFormatNVRAWZ			= 34,	/**    NOT SUPPORTED    **/		// formats for shadow depth mapping
	TKVTFFormatATIDST16			= 35,	/**    NOT SUPPORTED    **/		
	TKVTFFormatATIDST24			= 36,	/**    NOT SUPPORTED    **/		
	
	TKVTFFormatNVNULL			= 37,	/**    NOT SUPPORTED    **/		// Dummy format which takes no video memory
	
	
	// Compressed normal map formats
	
	TKVTFFormatATI1N			= 38,	/**    NOT SUPPORTED    **/		// Two-surface ATI1 format
	TKVTFFormatATI2N			= 39,	/**    NOT SUPPORTED    **/		// One-surface ATI2 / DXN format
	
	
	TKVTFFormatDefault			= TKVTFFormatDXT1,
	
};
typedef NSUInteger TKVTFFormat;



enum {
	TKVTFOperationNone			= 0UL << 0, // 0, no operations supported
	TKVTFOperationRead			= 1UL << 0, // 1, format can be read from a VTF file
	TKVTFOperationWrite			= 1UL << 1, // 2, format can be written to a VTF file
};
typedef NSUInteger TKVTFOperation;


/* The following are the keys that can be used in addition to the `TKImage*Key` keys found in `TKImageRep.h`. They can be used in TKImage's `VTFRepresentationWithOptions:error:`, and TKVTFImageRep's `VTFRepresentationOfImageRepsInArray:options:error:` methods. */

TEXTUREKIT_EXTERN NSString * const TKImageVTFCreateThumbnailImageKey;	// NSNumber containing a BOOL value for whether a thumbnail image should be created in the VTF file; default is `NO`



TEXTUREKIT_EXTERN NSString * const TKVTFType;			// UTI Type
TEXTUREKIT_EXTERN NSString * const TKVTFFileType;		// filename extension
TEXTUREKIT_EXTERN NSString * const TKVTFPboardType;


TEXTUREKIT_EXTERN NSString * const TKVTFUnsupportedFormatException;


enum {
	TKVTFMagic				= 0x56544600, // 'VTF\0'
	TKHTMLErrorMagic		= '<!DO'
};


@interface TKVTFImageRep : TKImageRep <NSCoding, NSCopying> {
	TKVTFFormat				format;
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData error:(NSError **)outError;

+ (id)imageRepWithData:(NSData *)aData error:(NSError **)outError;
- (id)initWithData:(NSData *)aData error:(NSError **)outError;


@property (readonly, nonatomic, assign) TKVTFFormat format;



/* Returns a zero-terminated list of all available (but not necessarily supported) TKVTFFormats. */
+ (const TKVTFFormat *)availableFormats;


/* Returns an NSArray of NSNumbers containing the enumerated type values of all TKVTFFormats which support the `operationMask`. */
+ (NSArray *)availableFormatsForOperationMask:(TKVTFOperation)operationMask;


/* Returns a human-readable string giving the name of the given format. */
+ (NSString *)localizedNameOfFormat:(TKVTFFormat)format;


/* 
 
 
 
 */
/* Returns the supported operation mask for the specified format. */
+ (TKVTFOperation)operationMaskForFormat:(TKVTFFormat)format;



/* Will raise an exception if `format` does not support `TKVTFOperationWrite` operations. */
+ (void)setDefaultFormat:(TKVTFFormat)format;
+ (TKVTFFormat)defaultFormat;


+ (BOOL)isDXTCompressionQualityApplicableToFormat:(TKVTFFormat)format;


/* See TKImageRep.h for more info on the allowed key/value pairs for the `options` dictionary in the following 2 methods. */
+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options error:(NSError **)outError;

/* Will raise an exception if `format` does not support `TKVTFOperationWrite` operations. */
+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)format quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options error:(NSError **)outError;


@end


