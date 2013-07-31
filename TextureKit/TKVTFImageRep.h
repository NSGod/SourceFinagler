//
//  TKVTFImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2013 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>

//	http://developer.valvesoftware.com/wiki/Valve_Texture_Format
//  
//	note: "Bluescreen" Alpha uses any pixel with a pixel of R0, G0, B255 as transparent.

enum {
	TKVTFFormatRGB				= 0,	// 24 bpp
	TKVTFFormatDXT1				= 1,	//  4 bpp
	TKVTFFormatDXT1a			= 2,	//  4 bpp - DXT1 with 1-bit Alpha
	TKVTFFormatDXT3				= 3,	//  8 bpp
	TKVTFFormatDXT5				= 4,	//  8 bpp
	
	TKVTFFormatRGBA				= 5,	// 32 bpp
	TKVTFFormatARGB				= 6,	// 32 bpp

	TKVTFFormatBluescreenRGB	= 7,	// 24 bpp - Red, Green, Blue, "BlueScreen" Alpha
	TKVTFFormatRGB565			= 8,	// 16 bpp
	
	TKVTFFormatBGR				= 9,	// 24 bpp
	TKVTFFormatBGRA				= 10,	// 32 bpp
	TKVTFFormatBGRX				= 11,	// 32 bpp
	TKVTFFormatABGR				= 12,	// 32 bpp
	
	TKVTFFormatBluescreenBGR	= 13,	// 32 bpp
	TKVTFFormatBGR565			= 14,	// 16 bpp
	TKVTFFormatBGRX5551			= 15,	// 16 bpp - Blue, Green, Red, Unused 
	TKVTFFormatBGRA5551			= 16,	// 16 bpp
	TKVTFFormatBGRA4444			= 17,	// 16 bpp
	
	TKVTFFormatI				= 18,	//  8 bpp - Luminance
	TKVTFFormatIA				= 19,	// 16 bpp - Luminance, Alpha
	TKVTFFormatP				= 20,	//  8 bpp - Paletted
	TKVTFFormatA				= 21,	//  8 bpp - Alpha
	
	TKVTFFormatRGBA16161616		= 22,	// 64 bpp - integer HDR format
	TKVTFFormatRGBA16161616F	= 23,	// 64 bpp - floating point HDR format
	
	TKVTFFormatR32F				= 24,	// 32 bpp - Luminance
	TKVTFFormatRGB323232F		= 25,	// 96 bpp
	TKVTFFormatRGBA32323232F	= 26,	// 128 bpp
	
	TKVTFFormatUV				= 27,	// 16 bpp - 2 channel format for DuDv/Normal maps
	TKVTFFormatUVWQ				= 28,	// 32 bpp - 4 channel format for DuDv/Normal maps
	TKVTFFormatUVLX				= 29,	// 32 bpp - 4 channel format for DuDv/Normal maps
	
	TKVTFFormatNVDST16			= 30,
	TKVTFFormatNVDST24			= 31,
	TKVTFFormatNVINTZ			= 32,
	TKVTFFormatNVRAWZ			= 33,
	
	TKVTFFormatATIDST16			= 34,
	TKVTFFormatATIDST24			= 35,
	
	TKVTFFormatNVNULL			= 36,
	
	TKVTFFormatATI2N			= 37,
	TKVTFFormatATI1N			= 38,
	
	TKVTFFormatDefault			= TKVTFFormatDXT1,
	
	TKVTFNoFormat				= 1000
};
typedef NSUInteger TKVTFFormat;



TEXTUREKIT_EXTERN NSString *NSStringFromVTFFormat(TKVTFFormat aFormat);
TEXTUREKIT_EXTERN TKVTFFormat TKVTFFormatFromString(NSString *aFormat);


TEXTUREKIT_EXTERN NSString * const TKVTFType;			// UTI Type
TEXTUREKIT_EXTERN NSString * const TKVTFFileType;		// filename extension
TEXTUREKIT_EXTERN NSString * const TKVTFPboardType;


enum {
	TKVTFMagic				= 0x56544600, // 'VTF\0'
	TKHTMLErrorMagic		= '<!DO'
};


@interface TKVTFImageRep : TKImageRep <NSCoding, NSCopying> {
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData;
+ (id)imageRepWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;

+ (TKVTFFormat)defaultFormat;
+ (void)setDefaultFormat:(TKVTFFormat)aFormat;


+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options;

+ (NSData *)VTFRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality options:(NSDictionary *)options;


@end


