//
//  TKIWIImageRep.h
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>


#pragma pack(1)

struct TKIWIHeader {
	UInt32		signature;
	UInt8		format;
	UInt8		flags;
	UInt16		width;
	UInt16		height;
} TKIWIHeader;

#pragma pack()

typedef TKIWIHeader TKIWIHeader;


enum {
	TKIWIFormatARGB				= 0x01,	// 32 bpp
	TKIWIFormatRGB				= 0x02,	// 24 bpp
	
	TKIWIFormatARGB4			= 0x03,	// 24 bpp
	
	TKIWIFormatA				= 0x04,	// 8  bpp - Alpha
	
	TKIWIFormatJPG				= 0x07,	// 24 bpp 
	
	TKIWIFormatDXT1				= 0x0b,	// 4 bpp
	TKIWIFormatDXT3				= 0x0c,	// 8 bpp
	TKIWIFormatDXT5				= 0x0d,	// 8 bpp
	
	
	TKIWIFormatDefault			= TKIWIFormatDXT5,
	
	TKIWINoFormat				= 1000
};
typedef NSUInteger TKIWIFormat;

//TEXTUREKIT_EXTERN NSString *NSStringFromVTFFormat(TKVTFFormat aFormat);

TEXTUREKIT_EXTERN NSString * const TKIWIType;
TEXTUREKIT_EXTERN NSString * const TKIWIFileType;
TEXTUREKIT_EXTERN NSString * const TKIWIPboardType;

extern const OSType TKIWIMagic;	// 'IWi\r'


@interface TKIWIImageRep : TKImageRep <NSCoding, NSCopying> {
	TKIWIHeader			header;
	
}

+ (NSArray *)imageRepsWithData:(NSData *)aData;
+ (id)imageRepWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;

+ (TKIWIFormat)defaultFormat;
+ (void)setDefaultFormat:(TKIWIFormat)aFormat;


+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps;
+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKIWIFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps;

@end


