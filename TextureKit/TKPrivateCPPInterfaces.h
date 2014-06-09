//
//  TKPrivateCPPInterfaces.h
//  Texture Kit
//
//  Created by Mark Douma on 3/15/2014.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKImageRep.h>
#import <TextureKit/TKVTFImageRep.h>
#import <TextureKit/TKDDSImageRep.h>

#import <VTF/VTF.h>
#import <NVTextureTools/NVTextureTools.h>
#import "TKPrivateInterfaces.h"


using namespace nv;
using namespace nvtt;


@interface TKVTFImageRep (TKNameAdditions)

+ (NSString *)localizedNameOfVTFImageFormat:(VTFImageFormat)format;

@end



@interface TKDDSImageRep (TKNameAdditions)


+ (NSString *)localizedNameOfDX9Format:(D3DFORMAT)format;

+ (NSString *)localizedNameOfDX10Format:(DXGI_FORMAT)format;


@end


//namespace TK {
//	
//	enum AlphaOperation {
//		AlphaOperationNone,
//		AlphaOperationUnpremultiply,
//		AlphaOperationPremultiply,
//	};
//	
//	enum ColorOperation {
//		ColorOperationNone,
//		ColorToGrayscale,
//		GrayscaleToColor,
//	};
//	
//	
//	struct ConversionInfo {
//		
//	public:
//		
//		inline ConversionInfo(TKPixelFormatInfo &inInfo, TKPixelFormatInfo &outInfo) : inInfo(inInfo), outInfo(outInfo) {
//			
//		}
//		
//		~ConversionInfo();
//		
//		
//		
//		TKPixelFormatInfo inInfo;
//		TKPixelFormatInfo outInfo;
//		
//	};
//
//}




//	TK::AlphaOperation alphaOp;



#pragma mark - TKWrapMode

typedef struct TKWrapModeInfo {
	TKWrapMode		wrapMode;
	WrapMode		ddsWrapMode;
	NSString		*description;
} TKWrapModeInfo;

static const TKWrapModeInfo TKWrapModeInfoTable[] = {
	{ TKWrapModeClamp,	WrapMode_Clamp,		@"TKWrapModeClamp"	},
	{ TKWrapModeRepeat, WrapMode_Repeat,	@"TKWrapModeRepeat"	},
	{ TKWrapModeMirror, WrapMode_Mirror,	@"TKWrapModeMirror"	},
};
static const NSUInteger TKWrapModeInfoTableCount = TK_ARRAY_SIZE(TKWrapModeInfoTable);

TEXTUREKIT_STATIC_INLINE TKWrapModeInfo TKWrapModeInfoFromWrapMode(TKWrapMode wrapMode) {
	NSCParameterAssert(wrapMode < TKWrapModeInfoTableCount);
	return TKWrapModeInfoTable[wrapMode];
}



#pragma mark - TKMipmapGenerationType

typedef struct TKMipmapGenerationTypeInfo {
	TKMipmapGenerationType		mipmapGenerationType;
	MipmapFilter				ddsMipmapFilter;
	VTFMipmapFilter				vtfMipmapFilter;
	NSString					*description;
} TKMipmapGenerationTypeInfo;

static const TKMipmapGenerationTypeInfo TKMipmapGenerationTypeInfoTable[] = {
	{ TKMipmapGenerationNoMipmaps,				(MipmapFilter)0,		(VTFMipmapFilter)0,		@"TKMipmapGenerationNoMipmaps" },
	{ TKMipmapGenerationUsingBoxFilter,			MipmapFilter_Box,		MIPMAP_FILTER_BOX,		@"TKMipmapGenerationUsingBoxFilter" },
	{ TKMipmapGenerationUsingTriangleFilter,	MipmapFilter_Triangle,	MIPMAP_FILTER_TRIANGLE,	@"TKMipmapGenerationUsingTriangleFilter" },
	{ TKMipmapGenerationUsingKaiserFilter,		MipmapFilter_Kaiser,	MIPMAP_FILTER_KAISER,	@"TKMipmapGenerationUsingKaiserFilter" },
};
static const NSUInteger TKMipmapGenerationTypeInfoTableCount = TK_ARRAY_SIZE(TKMipmapGenerationTypeInfoTable);

TEXTUREKIT_STATIC_INLINE TKMipmapGenerationTypeInfo TKMipmapGenerationTypeInfoFromMipmapGenerationType(TKMipmapGenerationType type) {
	NSCParameterAssert(type < TKMipmapGenerationTypeInfoTableCount);
	return TKMipmapGenerationTypeInfoTable[type];
}



#pragma mark - TKDXTCompressionQuality

typedef struct TKDXTCompressionQualityInfo {
	TKDXTCompressionQuality		quality;
	Quality						ddsQuality;
	VTFDXTQuality				vtfQuality;
	NSString					*description;
} TKDXTQualityInfo;

static const TKDXTCompressionQualityInfo TKDXTCompressionQualityInfoTable[] = {
	{TKDXTCompressionLowQuality,		Quality_Fastest,	DXT_QUALITY_LOW,		@"TKDXTCompressionLowQuality" },
	{TKDXTCompressionMediumQuality,		Quality_Normal,		DXT_QUALITY_MEDIUM,		@"TKDXTCompressionMediumQuality" },
	{TKDXTCompressionHighQuality,		Quality_Production,	DXT_QUALITY_HIGH,		@"TKDXTCompressionHighQuality" },
	{TKDXTCompressionHighestQuality,	Quality_Highest,	DXT_QUALITY_HIGHEST,	@"TKDXTCompressionHighestQuality" },
	{TKDXTCompressionNotApplicable,		(Quality)0,			(VTFDXTQuality)0,		@"TKDXTCompressionNotApplicable" },
};
static const NSUInteger TKDXTCompressionQualityInfoTableCount = TK_ARRAY_SIZE(TKDXTCompressionQualityInfoTable);

TEXTUREKIT_STATIC_INLINE TKDXTCompressionQualityInfo TKDXTCompressionQualityInfoFromDXTCompressionQuality(TKDXTCompressionQuality compressionQuality) {
	NSCParameterAssert(compressionQuality < TKDXTCompressionQualityInfoTableCount);
	return TKDXTCompressionQualityInfoTable[compressionQuality];
}



#pragma mark - TKResizeMode

typedef struct TKResizeModeInfo {
	TKResizeMode	resizeMode;
	RoundMode		ddsRoundMode;
	NSString		*description;
} TKResizeModeInfo;

static const TKResizeModeInfo TKResizeModeInfoTable[] = {
	{ TKResizeModeNone,					RoundMode_None,					@"TKResizeModeNone"	},
	{ TKResizeModeNextPowerOfTwo,		RoundMode_ToNextPowerOfTwo,		@"TKResizeModeNextPowerOfTwo" },
	{ TKResizeModeNearestPowerOfTwo,	RoundMode_ToNearestPowerOfTwo,	@"TKResizeModeNearestPowerOfTwo" },
	{ TKResizeModePreviousPowerOfTwo,	RoundMode_ToPreviousPowerOfTwo,	@"TKResizeModePreviousPowerOfTwo" },
};
static const NSUInteger TKResizeModeInfoTableCount = TK_ARRAY_SIZE(TKResizeModeInfoTable);

TEXTUREKIT_STATIC_INLINE TKResizeModeInfo TKResizeModeInfoFromResizeMode(TKResizeMode resizeMode) {
	NSCParameterAssert(resizeMode < TKResizeModeInfoTableCount);
	return TKResizeModeInfoTable[resizeMode];
}


#pragma mark - TKResizeFilter

typedef struct TKResizeFilterInfo {
	TKResizeFilter		resizeFilter;
	ResizeFilter		ddsResizeFilter;
	NSString			*description;
} TKResizeFilterInfo;

static const TKResizeFilterInfo TKResizeFilterInfoTable[] = {
	{ TKResizeFilterBox,		ResizeFilter_Box,		@"TKResizeFilterBox" },
	{ TKResizeFilterTriangle,	ResizeFilter_Triangle,	@"TKResizeFilterTriangle" },
	{ TKResizeFilterKaiser,		ResizeFilter_Kaiser,	@"TKResizeFilterKaiser" },
	{ TKResizeFilterMitchell,	ResizeFilter_Mitchell,	@"TKResizeFilterMitchell" },
};
static const NSUInteger TKResizeFilterInfoTableCount = TK_ARRAY_SIZE(TKResizeFilterInfoTable);

TEXTUREKIT_STATIC_INLINE TKResizeFilterInfo TKResizeFilterInfoFromResizeFilter(TKResizeFilter resizeFilter) {
	NSCParameterAssert(resizeFilter < TKResizeFilterInfoTableCount);
	return TKResizeFilterInfoTable[resizeFilter];
}


