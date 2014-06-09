//
//  TKDDSImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


//	"The DDS File Format Lives": http://blogs.msdn.com/b/chuckw/archive/2010/02/05/the-dds-file-format-lives.aspx
//	"DDS Update and 10:10:10:2 Problems": http://blogs.msdn.com/b/chuckw/archive/2010/06/15/dds-update-and-10-10-10-2-problems.aspx
//  "Legacy Formats: Map Direct3D 9 Formats to Direct3D 10": http://msdn.microsoft.com/en-us/library/windows/desktop/cc308051(v=vs.85).aspx
//

enum {
	
	TKDDSNoFormat					= 0,
	
	TKDDSFormatDXT1					= 1,
	TKDDSFormatDXT1a				= 2,	// DXT1 with 1-bit alpha
	TKDDSFormatDXT2					= 3,
	TKDDSFormatDXT3					= 4,
	TKDDSFormatDXT4					= 5,
	TKDDSFormatDXT5					= 6,
	TKDDSFormatDXT5n				= 7,	// Compressed HILO: R=1, G=y, B=0, A=x
	
	TKDDSFormatLA44					= 8,
	
	TKDDSFormatL					= 9,
	TKDDSFormatLA					= 10,
	TKDDSFormatA					= 11,
	
	TKDDSFormatP					= 12,		/**    NOT SUPPORTED    **/
	TKDDSFormatPA					= 13,		/**    NOT SUPPORTED    **/
	
	TKDDSFormatBGR233				= 14,
	TKDDSFormatBGR565				= 15,
	
	TKDDSFormatBGRA2338				= 16,
	
	TKDDSFormatBGRA4444				= 17,
	TKDDSFormatBGRX4444				= 18,
	
	TKDDSFormatBGRA5551				= 19,
	TKDDSFormatBGRX5551				= 20,
	
	TKDDSFormatRGBA					= 21,
	TKDDSFormatRGBX					= 22,
	
	TKDDSFormatBGR					= 23,
	TKDDSFormatBGRA					= 24,
	TKDDSFormatBGRX					= 25,
	
	TKDDSFormatRGBA1010102			= 26,
	TKDDSFormatBGRA1010102			= 27,
	
	TKDDSFormatL16					= 28,
	TKDDSFormatRG1616				= 29,
	TKDDSFormatRGBA16161616			= 30,
	
	TKDDSFormatR16F					= 31,
	TKDDSFormatRG1616F				= 32,
	TKDDSFormatRGBA16161616F		= 33,
	
	TKDDSFormatR32F					= 34,
	TKDDSFormatRG3232F				= 35,
	TKDDSFormatRGB323232F			= 36,
	TKDDSFormatRGBA32323232F		= 37,
	
	TKDDSFormatATI1					= 38,
	TKDDSFormatATI2					= 39,
	
	TKDDSFormatBC1					= 40,	// TKDDSFormatDXT1,
	TKDDSFormatBC1a					= 41,	// TKDDSFormatDXT1a,
	
	TKDDSFormatBC2					= 42,	// TKDDSFormatDXT3,
	
	TKDDSFormatBC3					= 43,	// TKDDSFormatDXT5,
	TKDDSFormatBC3n					= 44,	// TKDDSFormatDXT5n,
	
	TKDDSFormatBC4					= 45,	// 'ATI1'
	TKDDSFormatBC5					= 46,	// 3DC, 'ATI2'
	
	TKDDSFormatBC6					= 47,
	TKDDSFormatBC7					= 48,
	
	
	/**    NOT SUPPORTED below this point  **/
	
	
	TKDDSFormatUYVY					= 49,	// 'UYVY'	/**    NOT SUPPORTED    **/
	TKDDSFormatYUY2					= 50,	// 'YUY2'	/**    NOT SUPPORTED    **/
	
	TKDDSFormatRG_BG				= 51,	// 'RGBG'	/**    NOT SUPPORTED    **/
	TKDDSFormatGR_GB				= 52,	// 'GRGB'	/**    NOT SUPPORTED    **/
	
	TKDDSFormatUVL556				= 53,	/**    NOT SUPPORTED    **/
	TKDDSFormatUVLX					= 54,	/**    NOT SUPPORTED    **/
	
	TKDDSFormatUV					= 55,	/**    NOT SUPPORTED    **/
	TKDDSFormatUVWQ					= 56,	/**    NOT SUPPORTED    **/
	
	TKDDSFormatUV1616				= 57,	/**    NOT SUPPORTED    **/
	TKDDSFormatUVWQ16161616			= 58,	/**    NOT SUPPORTED    **/
	
	TKDDSFormatUVWA1010102			= 59,	/**    NOT SUPPORTED    **/
	
	TKDDSFormatCxVU					= 60,	/**    NOT SUPPORTED    **/
	
	TKDDSFormatDefault				= TKDDSFormatDXT1,
	
};
typedef NSUInteger TKDDSFormat;



enum {
	TKDDSContainerDX9				= 0,
	TKDDSContainerDX10				= 1,
	TKDDSContainerDefault			= TKDDSContainerDX9,
};
typedef NSUInteger TKDDSContainer;


enum {
	TKDDSOperationNone			= 0UL << 0, // 0, no operations supported for this format
	TKDDSOperationDX9Read		= 1UL << 0, // 1, format can be read from a DX9 container
	TKDDSOperationDX9Write		= 1UL << 1, // 2, format can be written to a DX9 container
	TKDDSOperationDX10Read		= 1UL << 2, // 4, format can be read from a DX10 container
	TKDDSOperationDX10Write		= 1UL << 3, // 8, format can be written to a DX10 container
};
typedef NSUInteger TKDDSOperation;



TEXTUREKIT_EXTERN NSString * const TKDDSType;			// UTI Type
TEXTUREKIT_EXTERN NSString * const TKDDSFileType;		// filename extension
TEXTUREKIT_EXTERN NSString * const TKDDSPboardType;


TEXTUREKIT_EXTERN NSString * const TKDDSUnsupportedFormatException;
TEXTUREKIT_EXTERN NSString * const TKDDSUnsupportedContainerAndFormatCombinationException;



enum {
	TKDDSMagic		= 'DDS '
};



@interface TKDDSImageRep : TKImageRep <NSCoding, NSCopying> {
	TKDDSFormat				format;
	TKDDSContainer			container;
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData error:(NSError **)outError;

+ (id)imageRepWithData:(NSData *)aData error:(NSError **)outError;
- (id)initWithData:(NSData *)aData error:(NSError **)outError;


@property (readonly, nonatomic, assign) TKDDSFormat format;
@property (readonly, nonatomic, assign) TKDDSContainer container;




/* Returns a zero-terminated list of all available (but not necessarily supported) TKDDSFormats. */
+ (const TKDDSFormat *)availableFormats;


/* Returns an NSArray of NSNumbers containing the enumerated type values of all TKDDSFormats which support at least part of the `operationMask`. */
+ (NSArray *)availableFormatsForOperationMask:(TKDDSOperation)operationMask;


/* Returns a human-readable string giving the name of the given format. */
+ (NSString *)localizedNameOfFormat:(TKDDSFormat)format;


/* 
 
 
 
 */
/* Returns the supported operation mask for the specified format. */
+ (TKDDSOperation)operationMaskForFormat:(TKDDSFormat)format;



/* Will raise an exception if `format` does not support either `TKDDSOperationDX9Write` or `TKDDSOperationDX10Write` operations. */
+ (void)setDefaultFormat:(TKDDSFormat)format;
+ (TKDDSFormat)defaultFormat;


+ (void)setDefaultContainer:(TKDDSContainer)container;
+ (TKDDSContainer)defaultContainer;


+ (BOOL)isDXTCompressionQualityApplicableToFormat:(TKDDSFormat)format;


/* See TKImageRep.h for more info on the allowed key/value pairs for the `options` dictionary in the following 2 methods. */
+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options error:(NSError **)outError;

/* Will raise an exception if `format` does not support either `TKDDSOperationDX9Write` or `TKDDSOperationDX10Write` operations. */
+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKDDSFormat)format quality:(TKDXTCompressionQuality)aQuality container:(TKDDSContainer)container options:(NSDictionary *)options error:(NSError **)outError;


@end



