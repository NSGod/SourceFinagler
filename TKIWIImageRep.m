//
//  TKIWIImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKIWIImageRep.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

#define TK_DEBUG 1

//#if TK_DEBUG
//#import "MDFoundationAdditions.h"
//#endif




NSString * const TKIWIType			= @"com.infinityward.iwi";
NSString * const TKIWIFileType		= @"iwi";
NSString * const TKIWIPboardType	= @"TKIWIPboardType";

const OSType TKIWIMagic				= 0x4957690d;	// 'IWi\r'



static TKIWIFormat defaultIWIFormat = TKIWIFormatDefault;


@interface TKIWIImageRep (TKPrivate)
+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly;
@end




@implementation TKIWIImageRep

/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *types = nil;
	if (types == nil) types = [[NSArray alloc] initWithObjects:TKIWIType, nil];
	return types;
}



+ (NSArray *)imageUnfilteredFileTypes {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	NSArray *superTypes = [super imageUnfilteredFileTypes];
//	NSLog(@"[%@ %@] superTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), superTypes);
	
	static NSArray *fileTypes = nil;
	if (fileTypes == nil) fileTypes = [[NSArray alloc] initWithObjects:TKIWIFileType, nil];
	return fileTypes;
}

+ (NSArray *)imageUnfilteredPasteboardTypes {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	if (imageUnfilteredPasteboardTypes == nil) {
		NSArray *types = [super imageUnfilteredPasteboardTypes];
		NSLog(@"[%@ %@] super's imageUnfilteredPasteboardTypes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), types);
		imageUnfilteredPasteboardTypes = [[types arrayByAddingObject:TKIWIPboardType] retain];
	}
	return imageUnfilteredPasteboardTypes;
}



+ (BOOL)canInitWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([aData length] < 4) return NO;
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKIWIMagic);
}

+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKIWIType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKIWIFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (TKIWIFormat)defaultFormat {
	return defaultIWIFormat;
}

+ (void)setDefaultFormat:(TKIWIFormat)aFormat {
	defaultIWIFormat = aFormat;
}


+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] IWIRepresentationOfImageRepsInArray:tkImageReps usingFormat:defaultIWIFormat quality:[[self class] defaultDXTCompressionQuality] createMipmaps:YES];
}

+ (NSData *)IWIRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKVTFFormat)aFormat quality:(TKDXTCompressionQuality)aQuality createMipmaps:(BOOL)createMipmaps {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([tkImageReps count] == 0) {
		return nil;
	}
	
	return nil;
}



+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	OSType magic = 0;
	[aData getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
#if TK_DEBUG
//	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	return nil;
}


+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO];
}

+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}

- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		self = nil;
		return self;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	TKIWIImageRep *copy = (TKIWIImageRep *)[super copyWithZone:zone];
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (self = [super initWithCoder:coder]) {
		
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	
}

@end

//struct TKVTFFormatMapping {
//	TKVTFFormat		format;
//	VTFImageFormat	vtfFormat;
//	TKPixelFormat	pixelFormat;
//	NSString		*description;
//};
//	
//static const TKVTFFormatMapping TKVTFFormatMappingTable[] = {
//	{ TKVTFFormatRGBA,			IMAGE_FORMAT_RGBA8888, TKPixelFormatRGBA, @"RGBA" },
//	{ TKVTFFormatABGR,			IMAGE_FORMAT_ABGR8888, TKPixelFormatRGBA, @"ABGR" },
//	{ TKVTFFormatRGB,			IMAGE_FORMAT_RGB888, TKPixelFormatRGBA, @"RGB" },
//	{ TKVTFFormatBGR,			IMAGE_FORMAT_BGR888, TKPixelFormatRGBA, @"BGR"  },
//	{ TKVTFFormatRGB565,		IMAGE_FORMAT_RGB565, TKPixelFormatRGBA, @"RGB565" },
//	{ TKVTFFormatI,				IMAGE_FORMAT_I8, TKPixelFormatRGBA, @"I" },
//	{ TKVTFFormatIA,			IMAGE_FORMAT_IA88, TKPixelFormatRGBA, @"IA" },
//	{ TKVTFFormatP,				IMAGE_FORMAT_P8, TKPixelFormatRGBA, @"P" },
//	{ TKVTFFormatA,				IMAGE_FORMAT_A8, TKPixelFormatRGBA, @"A" },
//	{ TKVTFFormatBluescreenRGB,	IMAGE_FORMAT_RGB888_BLUESCREEN, TKPixelFormatRGBA, @"BluescreenRGB" },
//	{ TKVTFFormatBluescreenBGR,	IMAGE_FORMAT_BGR888_BLUESCREEN, TKPixelFormatRGBA, @"BluescreenBGR"  },
//	{ TKVTFFormatARGB,			IMAGE_FORMAT_ARGB8888, TKPixelFormatARGB, @"ARGB" },
//	{ TKVTFFormatBGRA,			IMAGE_FORMAT_BGRA8888, TKPixelFormatRGBA, @"BGRA" },
//	{ TKVTFFormatDXT1,			IMAGE_FORMAT_DXT1, TKPixelFormatRGBA, @"DXT1" },
//	{ TKVTFFormatDXT3,			IMAGE_FORMAT_DXT3, TKPixelFormatRGBA, @"DXT3" },
//	{ TKVTFFormatDXT5,			IMAGE_FORMAT_DXT5, TKPixelFormatRGBA, @"DXT5" },
//	{ TKVTFFormatBGRX,			IMAGE_FORMAT_BGRX8888, TKPixelFormatRGBA, @"BGRX" },
//	{ TKVTFFormatBGR565,		IMAGE_FORMAT_BGR565, TKPixelFormatRGBA, @"BGR565" },
//	{ TKVTFFormatBGRX5551,		IMAGE_FORMAT_BGRX5551, TKPixelFormatRGBA, @"BGRX5551" },
//	{ TKVTFFormatBGRA4444,		IMAGE_FORMAT_BGRA4444, TKPixelFormatRGBA, @"BGRA4444" },
//	{ TKVTFFormatDXT1a,			IMAGE_FORMAT_DXT1_ONEBITALPHA, TKPixelFormatRGBA, @"DXT1a" },
//	{ TKVTFFormatBGRA5551,		IMAGE_FORMAT_BGRA5551, TKPixelFormatRGBA, @"BGRA5551"  },
//	{ TKVTFFormatUV,			IMAGE_FORMAT_UV88, TKPixelFormatRGBA, @"UV"  },
//	{ TKVTFFormatUVWQ,			IMAGE_FORMAT_UVWQ8888, TKPixelFormatRGBA, @"UVWQ"  },
//	{ TKVTFFormatRGBA16161616F,	IMAGE_FORMAT_RGBA16161616F, TKPixelFormatRGBA, @"RGBA16161616F" },
//	{ TKVTFFormatRGBA16161616,	IMAGE_FORMAT_RGBA16161616, TKPixelFormatRGBA16161616, @"RGBA16161616"  },
//	{ TKVTFFormatUVLX,			IMAGE_FORMAT_UVLX8888, TKPixelFormatRGBA, @"UVLX"  },
//	{ TKVTFFormatR32F,			IMAGE_FORMAT_R32F, TKPixelFormatRGBA, @"R32F" },
//	{ TKVTFFormatRGB323232F,	IMAGE_FORMAT_RGB323232F, TKPixelFormatRGBA, @"RGB323232F" },
//	{ TKVTFFormatRGBA32323232F,	IMAGE_FORMAT_RGBA32323232F, TKPixelFormatRGBA32323232F, @"RGBA32323232F" },
//	{ TKVTFFormatNVDST16,		IMAGE_FORMAT_NV_DST16, TKPixelFormatRGBA, @"NVDST16"  },
//	{ TKVTFFormatNVDST24,		IMAGE_FORMAT_NV_DST24, TKPixelFormatRGBA, @"NVDST24" },
//	{ TKVTFFormatNVINTZ,		IMAGE_FORMAT_NV_INTZ, TKPixelFormatRGBA, @"NVINTZ" },
//	{ TKVTFFormatNVRAWZ,		IMAGE_FORMAT_NV_RAWZ, TKPixelFormatRGBA, @"NVRAWZ"  },
//	{ TKVTFFormatATIDST16,		IMAGE_FORMAT_ATI_DST16, TKPixelFormatRGBA, @"ATIDST16" },
//	{ TKVTFFormatATIDST24,		IMAGE_FORMAT_ATI_DST24, TKPixelFormatRGBA, @"ATIDST24"  },
//	{ TKVTFFormatNVNULL,		IMAGE_FORMAT_NV_NULL, TKPixelFormatRGBA, @"NVNULL"  },
//	{ TKVTFFormatATI2N,			IMAGE_FORMAT_ATI2N, TKPixelFormatRGBA, @"ATI2N" },
//	{ TKVTFFormatATI1N,			IMAGE_FORMAT_ATI1N, TKPixelFormatRGBA, @"ATI1N" }
//};
//
//static const NSUInteger TKVTFImageFormatMappingTableCount = sizeof(TKVTFFormatMappingTable)/sizeof(TKVTFFormatMapping);
//

//NSString *NSStringFromVTFFormat(TKVTFFormat aFormat) {
//	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
//		if (TKVTFFormatMappingTable[i].format == aFormat) {
//			return TKVTFFormatMappingTable[i].description;
//		}
//	}
//	return @"<Unknown>";
//}
//	
//static inline VTFImageFormat VTFImageFormatFromTKVTFFormat(TKVTFFormat aFormat) {
//	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
//		if (TKVTFFormatMappingTable[i].format == aFormat) {
//			return TKVTFFormatMappingTable[i].vtfFormat;
//		}
//	}
//	return IMAGE_FORMAT_NONE;
//}
//
//static inline TKPixelFormat TKPixelFormatFromVTFImageFormat(VTFImageFormat aFormat) {
//	for (NSUInteger i = 0; i < TKVTFImageFormatMappingTableCount; i++) {
//		if (TKVTFFormatMappingTable[i].vtfFormat == aFormat) {
//			return TKVTFFormatMappingTable[i].pixelFormat;
//		}
//	}
//	return TKPixelFormatUnknown;
//}



