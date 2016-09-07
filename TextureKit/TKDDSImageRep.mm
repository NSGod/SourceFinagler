//
//  TKDDSImageRep.mm
//  Texture Kit
//
//  Created by Mark Douma on 9/25/2010.
//  Copyright (c) 2010-2014 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKError.h>
#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "TKPrivateInterfaces.h"
#import "TKFoundationAdditions.h"
#import "MDFoundationAdditions.h"

#import <NVTextureTools/NVTextureTools.h>
#import "TKPrivateCPPInterfaces.h"


#define TK_DEBUG 1


using namespace nv;
using namespace nvtt;

static NSData *TKCreateRGBDataFromImage(const nv::Image &image, TKPixelFormat convertedPixelFormat) NS_RETURNS_RETAINED;



enum {
	TKDDSHandlerNone,
	TKDDSHandlerNative,
	TKDDSHandlerNVImage,	
};
typedef NSUInteger TKDDSHandler;


#define TKNone			TKDDSOperationNone
#define DX9_R			TKDDSOperationDX9Read
#define DX9_RW			TKDDSOperationDX9Read | TKDDSOperationDX9Write
#define DX9_RW_DX10_R	TKDDSOperationDX9Read | TKDDSOperationDX9Write | TKDDSOperationDX10Read
#define DX9_RW_DX10_RW	TKDDSOperationDX9Read | TKDDSOperationDX9Write | TKDDSOperationDX10Read | TKDDSOperationDX10Write
#define DX9_R_DX10_RW	TKDDSOperationDX9Read | TKDDSOperationDX10Read | TKDDSOperationDX10Write
#define DX9_R_DX10_R	TKDDSOperationDX9Read | TKDDSOperationDX10Read
#define DX10_R			TKDDSOperationDX10Read
#define DX10_RW			TKDDSOperationDX10Read | TKDDSOperationDX10Write


typedef struct TKResizingInfo {
	TKPixelFormat		inputPixelFormat;
	TKPixelFormat		outputPixelFormat;
	InputFormat			ddsInputFormat;
	AlphaMode			ddsAlphaMode;
} TKResizingInfo;

static const TKResizingInfo TKResizingInfoTable[] = {
	
	{ TKPixelFormatUnknown,						TKPixelFormatUnknown, InputFormat_BGRA_8UB, AlphaMode_None },
	
	{ TKPixelFormatXRGB1555,					TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatRGBX5551,					TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	
	{ TKPixelFormatBGRX5551,					TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatXBGR1555,					TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	
	// NOTE: It doesn't appear that `AlphaMode_Premultiplied` is implemented in `nvtt::Surface`, so using `AlphaMode_Transparency` for time being
	
	{ TKPixelFormatA,							TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatL,							TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatLA,							TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedLA,				TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	
	{ TKPixelFormatRGB,							TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatXRGB,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatRGBX,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	
	{ TKPixelFormatBGRX,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	{ TKPixelFormatXBGR,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_None },
	
	{ TKPixelFormatARGB,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedARGB,			TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	{ TKPixelFormatRGBA,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedRGBA,			TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	
	{ TKPixelFormatBGRA,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedBGRA,			TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	{ TKPixelFormatABGR,						TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedABGR,			TKPixelFormatBGRA, InputFormat_BGRA_8UB, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	
	{ TKPixelFormatL16,							TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_None },
	{ TKPixelFormatLA1616,						TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedLA1616,			TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	
	
	{ TKPixelFormatRGB161616,					TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_None },
	{ TKPixelFormatRGBA16161616,				TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_Transparency },
	{ TKPixelFormatPremultipliedRGBA16161616,	TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_Transparency /* AlphaMode_Premultiplied */ },
	
	{ TKPixelFormatR32F,						TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_None },
	{ TKPixelFormatRGB323232F,					TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_None },
	{ TKPixelFormatRGBA32323232F,				TKPixelFormatRGBA32323232F, InputFormat_RGBA_32F, AlphaMode_Transparency },
};
static const NSUInteger TKResizingInfoTableCount = TK_ARRAY_SIZE(TKResizingInfoTable);

TEXTUREKIT_STATIC_INLINE TKResizingInfo TKResizingInfoFromPixelFormat(TKPixelFormat pixelFormat) {
	NSCParameterAssert(pixelFormat < TKResizingInfoTableCount);
	return TKResizingInfoTable[pixelFormat];
}


typedef struct TKDDSFormatCreationInfo {
	TKPixelFormat			inputPixelFormat;
	InputFormat				ddsInputFormat;
	Format					ddsFormat;
	nvtt::PixelType			ddsPixelType;
	uint					bitCount;
	uint					rmask;
	uint					gmask;
	uint					bmask;
	uint					amask;
	uint8					rsize;
	uint8					gsize;
	uint8					bsize;
	uint8					asize;
	BOOL					isDXTCompressed;
} TKDDSFormatCreationInfo;


static const TKDDSFormatCreationInfo TKDDSNoFormatCreationInfo = { };


typedef struct TKDDSFormatInfo {
	TKDDSFormat					format;
	FOURCC						ddsFourCC;
	D3DFORMAT					ddsDX9Format;
	DXGI_FORMAT					ddsDX10Format;
	TKPixelFormat				originalPixelFormat;
	TKDDSOperation				operationMask;
	TKDDSHandler				handler;
	TKPixelFormat				convertedPixelFormat;
	NSString					*description;
	TKDDSFormatCreationInfo		creationInfo;
} TKDDSFormatInfo;



static const TKDDSFormatInfo TKDDSFormatInfoTable[] = {
	
	{ TKDDSNoFormat,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,		TKPixelFormatUnknown,			@"TKDDSNoFormat",
																																																					TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatDXT1,				FOURCC_DXT1,				D3DFMT_DXT1,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"DXT1",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_DXT1,	PixelType_UnsignedNorm,	0,	0, 0, 0, 0, 0, 0, 0, 0, YES} },
	
	{ TKDDSFormatDXT1a,				FOURCC_DXT1,				D3DFMT_DXT1,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"DXT1a",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_DXT1a,	PixelType_UnsignedNorm,	0,	0, 0, 0, 0, 0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatDXT2,				FOURCC_DXT2,				D3DFMT_DXT2,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_R,			TKDDSHandlerNVImage,	TKPixelFormatPremultipliedRGBA,	@"DXT2",
																																																					TKDDSNoFormatCreationInfo },
	
	
	{ TKDDSFormatDXT3,				FOURCC_DXT3,				D3DFMT_DXT3,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"DXT3",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_DXT3,	PixelType_UnsignedNorm,	0,	0, 0, 0, 0, 0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatDXT4,				FOURCC_DXT4,				D3DFMT_DXT4,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_R,			TKDDSHandlerNVImage,	TKPixelFormatPremultipliedRGBA,	@"DXT4",
																																																					TKDDSNoFormatCreationInfo },
	
	
	{ TKDDSFormatDXT5,				FOURCC_DXT5,				D3DFMT_DXT5,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"DXT5",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_DXT5,	PixelType_UnsignedNorm,	0,	0, 0, 0, 0, 0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatDXT5n,				FOURCC_DXT5,				D3DFMT_DXT5,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"DXT5n",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_DXT5n,	PixelType_UnsignedNorm,	0,	0, 0, 0, 0, 0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatLA44,				(FOURCC)0,					D3DFMT_A4L4,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatLA44,			DX9_RW,			TKDDSHandlerNative,		TKPixelFormatLA,				@"LA44",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	8,	0x0000000F,	0,			0,			0x000000F0,		0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatL,					(FOURCC)0,					D3DFMT_L8,					DXGI_FORMAT_R8_UNORM,			TKPixelFormatL,				DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatL,					@"L",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	8,	0x000000FF,	0,			0,			0,				0, 0, 0, 0, NO} },
	
	{ TKDDSFormatLA,				(FOURCC)0,					D3DFMT_A8L8,				DXGI_FORMAT_R8G8_UNORM,			TKPixelFormatLA,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatLA,				@"LA",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x000000FF,	0,			0,			0x0000FF00,		0, 0, 0, 0, NO} },
	
	{ TKDDSFormatA,					(FOURCC)0,					D3DFMT_A8,					DXGI_FORMAT_A8_UNORM,			TKPixelFormatA,				DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatA,					@"A",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	8,	0,			0,			0,			0x000000FF,		0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatP,					(FOURCC)0,					D3DFMT_P8,					DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,		TKPixelFormatUnknown,			@"P",
																																																					TKDDSNoFormatCreationInfo },
	{ TKDDSFormatPA,				(FOURCC)0,					D3DFMT_A8P8,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,		TKPixelFormatUnknown,			@"PA",
																																																					TKDDSNoFormatCreationInfo },
	
	
	{ TKDDSFormatBGR233,			(FOURCC)0,					D3DFMT_R3G3B2,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"BGR233",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	8,	0x000000E0,	0x0000001C,	0x00000003,	0,				0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGR565,			(FOURCC)0,					D3DFMT_R5G6B5,				DXGI_FORMAT_B5G6R5_UNORM,		TKPixelFormatUnknown,		DX9_RW_DX10_R,	TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"BGR565",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x0000F800,	0x000007E0,	0x0000001F,	0,				0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGRA2338,			(FOURCC)0,					D3DFMT_A8R3G3B2,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BGRA2338",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x000000E0,	0x0000001C,	0x00000003,	0x0000FF00,		0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatBGRA4444,			(FOURCC)0,					D3DFMT_A4R4G4B4,			DXGI_FORMAT_B4G4R4A4_UNORM,		TKPixelFormatUnknown,		DX9_RW_DX10_R,	TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BGRA4444",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x00000F00,	0x000000F0,	0x0000000F,	0x0000F000,		0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGRX4444,			(FOURCC)0,					D3DFMT_X4R4G4B4,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGBX,				@"BGRX4444",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x00000F00,	0x000000F0,	0x0000000F,	0,				0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatBGRA5551,			(FOURCC)0,					D3DFMT_A1R5G5B5,			DXGI_FORMAT_B5G5R5A1_UNORM,		TKPixelFormatUnknown,		DX9_RW_DX10_R,	TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BGRA5551",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x00007C00,	0x000003E0,	0x0000001F,	0x00008000,		0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatBGRX5551,			(FOURCC)0,					D3DFMT_X1R5G5B5,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatBGRX,				@"BGRX5551",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x00007C00,	0x000003E0,	0x0000001F,	0,				0, 0, 0, 0, NO} },
	
	
	
	{ TKDDSFormatRGBA,				(FOURCC)0,					D3DFMT_A8B8G8R8,			DXGI_FORMAT_R8G8B8A8_UNORM,		TKPixelFormatRGBA,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGBA,				@"RGBA",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x000000FF,	0x0000FF00,	0x00FF0000,	0xFF000000,		0, 0, 0, 0, NO} },
	
	{ TKDDSFormatRGBX,				(FOURCC)0,					D3DFMT_X8B8G8R8,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatRGBX,			DX9_RW,			TKDDSHandlerNative,		TKPixelFormatRGBX,				@"RGBX",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x000000FF,	0x0000FF00,	0x00FF0000,	0,				0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatBGR,				(FOURCC)0,					D3DFMT_R8G8B8,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatBGR,			DX9_RW,			TKDDSHandlerNative,		TKPixelFormatRGB,				@"BGR",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	24,	0x00FF0000,	0x0000FF00,	0x000000FF,	0,				0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGRA,				(FOURCC)0,					D3DFMT_A8R8G8B8,			DXGI_FORMAT_B8G8R8A8_UNORM,		TKPixelFormatBGRA,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatBGRA,				@"BGRA",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x00FF0000,	0x0000FF00,	0x000000FF,	0xFF000000,		0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGRX,				(FOURCC)0,					D3DFMT_X8R8G8B8,			DXGI_FORMAT_B8G8R8X8_UNORM,		TKPixelFormatBGRX,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatBGRX,				@"BGRX",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x00FF0000,	0x0000FF00,	0x000000FF,	0,				0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatRGBA1010102,		(FOURCC)0,					D3DFMT_A2B10G10R10,			DXGI_FORMAT_R10G10B10A2_UNORM,	TKPixelFormatRGBA1010102,	DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGBA16161616,		@"RBGA1010102",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x000003FF,	0x000FFC00,	0x3FF00000,	0xC0000000,		0, 0, 0, 0, NO} },
	
	{ TKDDSFormatBGRA1010102,		(FOURCC)0,					D3DFMT_A2R10G10B10,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatBGRA1010102,	DX9_RW,			TKDDSHandlerNative,		TKPixelFormatRGBA16161616,		@"BGRA1010102",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x3FF00000,	0x000FFC00,	0x000003FF,	0xC0000000,		0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatL16,				(FOURCC)0,					D3DFMT_L16,					DXGI_FORMAT_R16_UNORM,			TKPixelFormatL16,			DX9_RW_DX10_RW,	TKDDSHandlerNative,		TKPixelFormatL16,				@"L16",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_UnsignedNorm,	16,	0x0000FFFF,	0,			0,			0,				16, 0, 0, 0, NO} },
	
	{ TKDDSFormatRG1616,			(FOURCC)0,					D3DFMT_G16R16,				DXGI_FORMAT_R16G16_UNORM,		TKPixelFormatRG1616,		DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGB161616,			@"RG1616",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_UnsignedNorm,	32,	0x0000FFFF,	0xFFFF0000,	0,			0,				0, 0, 0, 0, NO} },
	
	
	{ TKDDSFormatRGBA16161616,	(FOURCC)D3DFMT_A16B16G16R16,	D3DFMT_A16B16G16R16,		DXGI_FORMAT_R16G16B16A16_UNORM,	TKPixelFormatRGBA16161616,	DX9_R_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGBA16161616,		@"RGBA16161616",
																																																					TKDDSNoFormatCreationInfo },	
	
	
	
	{ TKDDSFormatR16F,			(FOURCC)D3DFMT_R16F,			D3DFMT_R16F,				DXGI_FORMAT_R16_FLOAT,			TKPixelFormatR16F,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatR32F,				@"R16F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_Float,	0, 0, 0, 0, 0,		16, 0, 0, 0, NO} },
	
	{ TKDDSFormatRG1616F,		(FOURCC)D3DFMT_G16R16F,			D3DFMT_G16R16F,				DXGI_FORMAT_R16G16_FLOAT,		TKPixelFormatRG1616F,		DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGB323232F,		@"RG1616F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_Float,	0, 0, 0, 0, 0,		16, 16, 0, 0, NO} },
	
	{ TKDDSFormatRGBA16161616F,	(FOURCC)D3DFMT_A16B16G16R16F,	D3DFMT_A16B16G16R16F,		DXGI_FORMAT_R16G16B16A16_FLOAT,	TKPixelFormatRGBA16161616F,	DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGBA32323232F,		@"RGBA16161616F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_Float,	0, 0, 0, 0, 0,		16, 16, 16, 16, NO} },
	
	
	
	{ TKDDSFormatR32F,			(FOURCC)D3DFMT_R32F,			D3DFMT_R32F,				DXGI_FORMAT_R32_FLOAT,			TKPixelFormatR32F,			DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatR32F,				@"R32F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA,	PixelType_Float,	0, 0, 0, 0, 0,		32, 0, 0, 0, NO} },
	
	{ TKDDSFormatRG3232F,		(FOURCC)D3DFMT_G32R32F,			D3DFMT_G32R32F,				DXGI_FORMAT_R32G32_FLOAT,		TKPixelFormatRG3232F,		DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGB323232F,		@"RG3232F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA, PixelType_Float, 0, 0, 0, 0, 0,		32, 32, 0, 0, NO} },
	
	{ TKDDSFormatRGB323232F,	(FOURCC)0,						D3DFMT_UNKNOWN,				DXGI_FORMAT_R32G32B32_FLOAT,	TKPixelFormatRGB323232F,	DX10_R,			TKDDSHandlerNative,		TKPixelFormatRGB323232F,		@"RGB323232F",
																																																					TKDDSNoFormatCreationInfo },	
	
	{ TKDDSFormatRGBA32323232F,	(FOURCC)D3DFMT_A32B32G32R32F,	D3DFMT_A32B32G32R32F,		DXGI_FORMAT_R32G32B32A32_FLOAT,	TKPixelFormatRGBA32323232F,	DX9_RW_DX10_R,	TKDDSHandlerNative,		TKPixelFormatRGBA32323232F,		@"RGBA32323232F",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_RGBA, PixelType_Float, 0, 0, 0, 0, 0,		32, 32, 32, 32, NO} },
	
	
	
	{ TKDDSFormatATI1,				FOURCC_ATI1,				(D3DFORMAT)FOURCC_ATI1,		DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"ATI1",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC4,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES } },
	
	{ TKDDSFormatATI2,				FOURCC_ATI2,				(D3DFORMAT)FOURCC_ATI2,		DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		DX9_RW,			TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"ATI2",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC5,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC1,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC1_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC1",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC1,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	{ TKDDSFormatBC1a,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC1_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC1a",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC1a,	PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC2,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC2_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC2",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC2,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC3,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC3_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC3",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC3,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	{ TKDDSFormatBC3n,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC3_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC3n",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC3n,	PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC4,				FOURCC_BC4U,				(D3DFORMAT)FOURCC_BC4U,		DXGI_FORMAT_BC4_UNORM,			TKPixelFormatUnknown,		DX9_R_DX10_RW,	TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"BC4",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC4,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC5,				FOURCC_BC5U,				(D3DFORMAT)FOURCC_BC5U,		DXGI_FORMAT_BC5_UNORM,			TKPixelFormatUnknown,		DX9_R_DX10_RW,	TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"BC5",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC5,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	{ TKDDSFormatBC6,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC6H_UF16,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGB,				@"BC6",
																		{TKPixelFormatRGBA32323232F,	InputFormat_RGBA_32F,	Format_BC6,		PixelType_Float,		0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	{ TKDDSFormatBC7,				(FOURCC)0,					D3DFMT_UNKNOWN,				DXGI_FORMAT_BC7_UNORM,			TKPixelFormatUnknown,		DX10_RW,		TKDDSHandlerNVImage,	TKPixelFormatRGBA,				@"BC7",
																					{TKPixelFormatBGRA,	InputFormat_BGRA_8UB,	Format_BC7,		PixelType_UnsignedNorm,	0, 0, 0, 0, 0,	0, 0, 0, 0, YES} },
	
	
	/**    NOT SUPPORTED below this point  **/
	
	{ TKDDSFormatUYVY,		(FOURCC)D3DFMT_UYVY,				D3DFMT_UYVY,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UYVY", TKDDSNoFormatCreationInfo },
	{ TKDDSFormatYUY2,		(FOURCC)D3DFMT_YUY2,				D3DFMT_YUY2,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"YUY2", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatRG_BG,		(FOURCC)D3DFMT_R8G8_B8G8,			D3DFMT_R8G8_B8G8,			DXGI_FORMAT_R8G8_B8G8_UNORM,	TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"RG_BG", TKDDSNoFormatCreationInfo },
	{ TKDDSFormatGR_GB,		(FOURCC)D3DFMT_G8R8_G8B8,			D3DFMT_G8R8_G8B8,			DXGI_FORMAT_G8R8_G8B8_UNORM,	TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"GR_GB", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatUVL556,			(FOURCC)0,					D3DFMT_L6V5U5,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UVL556", TKDDSNoFormatCreationInfo },
	{ TKDDSFormatUVLX,				(FOURCC)0,					D3DFMT_X8L8V8U8,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UVLX", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatUV,				(FOURCC)0,					D3DFMT_V8U8,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UV", TKDDSNoFormatCreationInfo },
	{ TKDDSFormatUVWQ,				(FOURCC)0,					D3DFMT_Q8W8V8U8,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UVWQ", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatUV1616,			(FOURCC)0,					D3DFMT_V16U16,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UV1616", TKDDSNoFormatCreationInfo },
	{ TKDDSFormatUVWQ16161616,	(FOURCC)D3DFMT_Q16W16V16U16,	D3DFMT_Q16W16V16U16,		DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UVWQ16161616", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatUVWA1010102,		(FOURCC)0,					D3DFMT_A2W10V10U10,			DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"UVWA1010102", TKDDSNoFormatCreationInfo },
	
	{ TKDDSFormatCxVU,				(FOURCC)0,					D3DFMT_CxV8U8,				DXGI_FORMAT_UNKNOWN,			TKPixelFormatUnknown,		TKNone,			TKDDSHandlerNone,	TKPixelFormatUnknown,	@"CxVU", TKDDSNoFormatCreationInfo },
};
static const NSUInteger TKDDSFormatInfoTableCount = TK_ARRAY_SIZE(TKDDSFormatInfoTable);


static TKDDSFormat availableFormats[TKDDSFormatInfoTableCount];


__attribute__((constructor)) static void TKDDSAvailableFormatsInit() {
	
	NSUInteger availableFormatsIndex = 0;
	
	for (NSUInteger i = 0; i < TKDDSFormatInfoTableCount; i++) {
		if (TKDDSFormatInfoTable[i].format != TKDDSNoFormat) {
			availableFormats[availableFormatsIndex] = TKDDSFormatInfoTable[i].format;
			availableFormatsIndex++;
		}
	}
	availableFormats[availableFormatsIndex] = TKDDSNoFormat;
}



TEXTUREKIT_STATIC_INLINE TKDDSFormatInfo TKDDSFormatInfoFromDDSFormat(TKDDSFormat aFormat) {
	NSCParameterAssert(aFormat < TKDDSFormatInfoTableCount);
	return TKDDSFormatInfoTable[aFormat];
}


TEXTUREKIT_STATIC_INLINE TKDDSFormatInfo TKDDSFormatInfoFromDX10Format(DXGI_FORMAT aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatInfoTableCount; i++) {
		if (TKDDSFormatInfoTable[i].ddsDX10Format == aFormat) return TKDDSFormatInfoTable[i];
	}
	return TKDDSFormatInfoTable[0];
}

TEXTUREKIT_STATIC_INLINE TKDDSFormatInfo TKDDSFormatInfoFromDX9Format(D3DFORMAT aFormat) {
	for (NSUInteger i = 0; i < TKDDSFormatInfoTableCount; i++) {
		if (TKDDSFormatInfoTable[i].ddsDX9Format == aFormat) return TKDDSFormatInfoTable[i];
	}
	return TKDDSFormatInfoTable[0];
}


TEXTUREKIT_STATIC_INLINE AlphaMode AlphaModeFromCGAlphaInfo(CGImageAlphaInfo alphaInfo) {
	if (alphaInfo == kCGImageAlphaNone || alphaInfo == kCGImageAlphaNoneSkipLast || alphaInfo == kCGImageAlphaNoneSkipFirst) {
		return AlphaMode_None;
	} else if (alphaInfo == kCGImageAlphaPremultipliedLast || alphaInfo == kCGImageAlphaPremultipliedFirst) {
		return AlphaMode_Premultiplied;
	} else if (alphaInfo == kCGImageAlphaLast || alphaInfo == kCGImageAlphaFirst) {
		return AlphaMode_Transparency;
	}
	return AlphaMode_None;
}



NSString * const TKDDSType			= @"com.microsoft.dds";
NSString * const TKDDSFileType		= @"dds";
NSString * const TKDDSPboardType	= @"com.microsoft.dds";


NSString * const TKDDSUnsupportedFormatException							= @"TKDDSUnsupportedFormatException";
NSString * const TKDDSUnsupportedContainerAndFormatCombinationException		= @"TKDDSUnsupportedContainerAndFormatCombinationException";


// NSCoding keys
static NSString * const TKDDSFormatKey			= @"TKDDSFormat";
static NSString * const TKDDSContainerKey		= @"TKDDSContainer";



struct TKErrorHandler : public ErrorHandler {
	
	void error(Error e) {
		m_error = e;
	}
	
	Error getError() const {
		return m_error;
	}
	
private:
	Error m_error;
};


struct TKOutputHandler : public OutputHandler {
	
	TKOutputHandler(NSMutableData *imageData) : imageData(imageData) {
		
	}
	
	virtual ~TKOutputHandler() { }
	
    virtual void beginImage(int size, int width, int height, int depth, int face, int miplevel) {
#if TK_DEBUG
//		printf("TKOutputHandler::beginImage(size == %d, width == %d, height == %d, depth == %d, face == %d, mipmapLevel == %d)\n", size, width, height, depth, face, miplevel);
#endif
        // ignore.
    }
	
    virtual bool writeData(const void * data, int size) {
#if TK_DEBUG
//		printf("TKOutputHandler::writeData()\n");
#endif
		
		if (this->imageData) [this->imageData appendBytes:data length:size];
        return true;
    }
	
	virtual void endImage() {
#if TK_DEBUG
//		printf("TKOutputHandler::endImage()\n");
#endif
		
	}
	
	NSMutableData *imageData;
};



static TKDDSFormat defaultDDSFormat = TKDDSFormatDefault;

static TKDDSContainer defaultContainer = TKDDSContainerDefault;


@implementation TKDDSImageRep

@synthesize format;
@synthesize container;


/* Implemented by subclassers to indicate what UTI-identified data types they can deal with. */
+ (NSArray *)imageUnfilteredTypes {
	static NSArray *imageUnfilteredTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredTypes == nil) imageUnfilteredTypes = [[NSArray alloc] initWithObjects:TKDDSType, nil];
	}
	return imageUnfilteredTypes;
}


+ (NSArray *)imageUnfilteredFileTypes {
	static NSArray *imageUnfilteredFileTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredFileTypes == nil) imageUnfilteredFileTypes = [[NSArray alloc] initWithObjects:TKDDSFileType, nil];
	}
	return imageUnfilteredFileTypes;
}


+ (NSArray *)imageUnfilteredPasteboardTypes {
	static NSArray *imageUnfilteredPasteboardTypes = nil;
	
	@synchronized(self) {
		if (imageUnfilteredPasteboardTypes == nil) {
			imageUnfilteredPasteboardTypes = [[[super imageUnfilteredPasteboardTypes] arrayByAddingObject:TKDDSPboardType] retain];
		}
	}
	return imageUnfilteredPasteboardTypes;
}


//+ (BOOL)canInitWithPasteboard:(NSPasteboard *)pasteboard {
//	
//}


+ (BOOL)canInitWithData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([data length] < sizeof(OSType)) return NO;
	OSType magic = 0;
	[data getBytes:&magic length:sizeof(magic)];
	magic = NSSwapBigIntToHost(magic);
	return (magic == TKDDSMagic);
}


+ (Class)imageRepClassForType:(NSString *)type {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([type isEqualToString:TKDDSType]) {
		return [self class];
	}
	return [super imageRepClassForType:type];
}

+ (Class)imageRepClassForFileType:(NSString *)fileType {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([fileType isEqualToString:TKDDSFileType]) {
		return [self class];
	}
	return [super imageRepClassForFileType:fileType];
}


+ (const TKDDSFormat *)availableFormats {
	return (const TKDDSFormat *)availableFormats;
}


+ (NSArray *)availableFormatsForOperationMask:(TKDDSOperation)operationMask {
	NSMutableArray *availableFormats = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < TKDDSFormatInfoTableCount; i++) {
		if (TKDDSFormatInfoTable[i].operationMask & operationMask) {
			[availableFormats addObject:[NSNumber numberWithUnsignedInteger:TKDDSFormatInfoTable[i].format]];
		}
	}
	return availableFormats;
}


+ (NSString *)localizedNameOfFormat:(TKDDSFormat)format {
	NSParameterAssert(format < TKDDSFormatInfoTableCount);
	return TKDDSFormatInfoTable[format].description;
}


+ (NSString *)localizedNameOfDX9Format:(D3DFORMAT)format {
	NSString *name = TKDDSFormatInfoFromDX9Format(format).description;
	if ([name isEqualToString:TKDDSFormatInfoFromDDSFormat(TKDDSNoFormat).description]) return nil;
	return name;
}


+ (NSString *)localizedNameOfDX10Format:(DXGI_FORMAT)format {
	NSString *name = TKDDSFormatInfoFromDX10Format(format).description;
	if ([name isEqualToString:TKDDSFormatInfoFromDDSFormat(TKDDSNoFormat).description]) return nil;
	return name;
}



+ (TKDDSOperation)operationMaskForFormat:(TKDDSFormat)format {
#if TK_DEBUG
//	NSLog(@"[%@ %@] format == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:format]);
#endif
	NSParameterAssert(format < TKDDSFormatInfoTableCount);
	return TKDDSFormatInfoTable[format].operationMask;
}



+ (void)raiseUnsupportedFormatExceptionWithDDSFormat:(TKDDSFormat)aFormat {
#if TK_DEBUG
	NSLog(@"[%@ %@] aFormat == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:aFormat]);
#endif
	[[NSException exceptionWithName:TKDDSUnsupportedFormatException reason:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a supported DDS format.", @""), [[self class] localizedNameOfFormat:aFormat]] userInfo:nil] raise];
}


+ (void)raiseUnsupportedContainerAndFormatCombinationExceptionWithDDSFormat:(TKDDSFormat)aFormat container:(TKDDSContainer)container {
#if TK_DEBUG
	NSLog(@"[%@ %@] aFormat == %@, container == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:aFormat], (container == TKDDSContainerDX9 ? @"TKDDSContainerDX9" : @"TKDDSContainerDX10"));
#endif
	[[NSException exceptionWithName:TKDDSUnsupportedContainerAndFormatCombinationException
							 reason:[NSString stringWithFormat:@"\"%@\" is not a supported DDS format for the %@ container type.", [[self class] localizedNameOfFormat:aFormat], (container == TKDDSContainerDX9 ? @"TKDDSContainerDX9" : @"TKDDSContainerDX10")]
						   userInfo:nil] raise];
}


+ (TKDDSFormat)defaultFormat {
	TKDDSFormat defaultFormat = 0;
	@synchronized(self) {
		defaultFormat = defaultDDSFormat;
	}
	return defaultFormat;
}

+ (void)setDefaultFormat:(TKDDSFormat)format {
	@synchronized(self) {
		if (([[self class] operationMaskForFormat:format] & TKDDSOperationDX9Write) != TKDDSOperationDX9Write ||
			([[self class] operationMaskForFormat:format] & TKDDSOperationDX10Write) != TKDDSOperationDX10Write) {
			[[self class] raiseUnsupportedFormatExceptionWithDDSFormat:format];
		}
		defaultDDSFormat = format;
	}
}


+ (TKDDSContainer)defaultContainer {
	TKDDSContainer aDefaultContainer = 0;
	@synchronized(self) {
		aDefaultContainer = defaultContainer;
	}
	return aDefaultContainer;
}


+ (void)setDefaultContainer:(TKDDSContainer)container {
	@synchronized(self) {
		defaultContainer = container;
	}
}


+ (BOOL)isDXTCompressionQualityApplicableToFormat:(TKDDSFormat)format {
	NSParameterAssert(format < TKDDSFormatInfoTableCount);
	return TKDDSFormatInfoTable[format].creationInfo.isDXTCompressed;
}



#pragma mark - reading

+ (NSArray *)imageRepsWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData error:NULL];
}


+ (NSArray *)imageRepsWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepsWithData:aData firstRepresentationOnly:NO error:outError];
}


+ (NSArray *)imageRepsWithData:(NSData *)aData firstRepresentationOnly:(BOOL)firstRepOnly error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
#if TK_DEBUG
//	OSType magic = 0;
//	[aData getBytes:&magic length:sizeof(magic)];
//	magic = NSSwapBigIntToHost(magic);
//	NSLog(@"[%@ %@] magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd),  (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
#endif
	
	DirectDrawSurface dds((unsigned char *)[aData bytes], [aData length]);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] dds info == \n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	dds.printInfo();
#endif
	
	if (!dds.isValid()) {
		NSLog(@"[%@ %@] dds image is not valid, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		dds.printInfo();
		
		if (outError) {
			*outError = [NSError errorWithDomain:TKErrorDomain
											code:TKErrorCorruptDDSFile
										userInfo:nil];
		}
		return nil;
	}
	
	TKDDSFormatInfo formatInfo = (dds.header.hasDX10Header() ? TKDDSFormatInfoFromDX10Format((DXGI_FORMAT)dds.header.header10.dxgiFormat) : TKDDSFormatInfoFromDX9Format((D3DFORMAT)dds.header.d3d9Format()));
	
	BOOL supported = (dds.header.hasDX10Header() ? (formatInfo.operationMask & TKDDSOperationDX10Read) == TKDDSOperationDX10Read : (formatInfo.operationMask & TKDDSOperationDX9Read) == TKDDSOperationDX9Read);
	
	if (supported == NO) {
		if (outError) {
			*outError = [NSError errorWithDomain:TKErrorDomain
											code:TKErrorUnsupportedDDSFormat
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"\"%@\" is not a supported DDS format.", @""), formatInfo.description],NSLocalizedDescriptionKey, nil]];
		}
		return nil;
	}
	
	const NSUInteger mipmapCount = dds.mipmapCount();
	const NSUInteger faceCount = dds.isTextureCube() ? 6 : 1;
	
	const TKPixelFormatInfo pixelFormatInfo = TKPixelFormatInfoFromPixelFormat(formatInfo.convertedPixelFormat);
	
	
	NSMutableArray *bitmapImageReps = [NSMutableArray array];
	
	for (NSUInteger mipmapIndex = 0; mipmapIndex < mipmapCount; mipmapIndex++) {
		for (NSUInteger faceIndex = 0; faceIndex < faceCount; faceIndex++) {
			
			NSData *mipmapData = nil;
			
			const NSUInteger mipmapWidth = dds.surfaceWidth(mipmapIndex);
			const NSUInteger mipmapHeight = dds.surfaceHeight(mipmapIndex);
			
			if (formatInfo.handler == TKDDSHandlerNVImage) {
				Image nvImage;
				dds.mipmap(&nvImage, faceIndex, mipmapIndex);
				
				mipmapData = TKCreateRGBDataFromImage(nvImage, formatInfo.convertedPixelFormat);
				
			} else if (formatInfo.handler == TKDDSHandlerNative) {
				
				const NSUInteger surfaceSize = dds.surfaceSize(mipmapIndex);
				
				unsigned char *surfaceBytes = (unsigned char *)malloc(surfaceSize);
				
				if (surfaceBytes == NULL) {
					NSLog(@"[%@ %@] malloc(%llu) (for faceIndex == %lu, mipmapIndex == %lu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long long)surfaceSize, (unsigned long)faceIndex, (unsigned long)mipmapIndex);
					continue;
				}
				
				if (!dds.readSurface(faceIndex, mipmapIndex, surfaceBytes, surfaceSize)) {
					NSLog(@"[%@ %@] dds.readSurface() (for faceIndex == %lu, mipmapIndex == %lu) returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)faceIndex, (unsigned long)mipmapIndex);
					free(surfaceBytes);
					continue;
				}
				
				NSData *surfaceData = [[NSData alloc] initWithBytes:surfaceBytes length:surfaceSize];
				
				free(surfaceBytes);
				
#if 0
				if (pixelFormatInfo.bitmapInfo & kCGBitmapFloatComponents) {
					if (mipmapIndex == 0 && surfaceData.length > 512) {
						NSData *subdata = [surfaceData subdataWithRange:NSMakeRange(0, 512)];
						NSLog(@"[%@ %@] surfaceData == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [subdata enhancedFloatDescriptionForComponentCount:2]);
					}
				} else {
					if (mipmapIndex == 0 && surfaceData.length > 512) {
						NSData *subdata = [surfaceData subdataWithRange:NSMakeRange(0, 512)];
						NSLog(@"[%@ %@] surfaceData == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [subdata enhancedDescription]);
					}
				}
#endif
				
				if (formatInfo.originalPixelFormat != formatInfo.convertedPixelFormat) {
					// need to convert data before Quartz can use it...
					// For example, we need to convert from TKPixelFormatRGBA16161616F (16 bpc floating point) to TKPixelFormatRGBA32323232F (32 bpc floating point), which Quartz can understand
					
//					NSData *convertedMipmapData = [[self class] dataByConvertingData:surfaceData inFormat:formatInfo.originalPixelFormat toFormat:formatInfo.convertedPixelFormat pixelCount:mipmapWidth * mipmapHeight ignoreAlpha:NO];
					NSData *convertedMipmapData = [[self class] dataByConvertingData:surfaceData inFormat:formatInfo.originalPixelFormat toFormat:formatInfo.convertedPixelFormat pixelCount:mipmapWidth * mipmapHeight options:TKPixelFormatConversionOptionsDefault];
					
					if (convertedMipmapData == nil) {
						NSLog(@"[%@ %@] ERROR: failed to convert data from %@ to %@! faceIndex == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd),
							  TKStringFromPixelFormat(formatInfo.originalPixelFormat), TKStringFromPixelFormat(formatInfo.convertedPixelFormat), (unsigned long)faceIndex, (unsigned long)mipmapIndex);
						[surfaceData release];
						continue;
					}
					
					mipmapData = [convertedMipmapData retain];
					
					[surfaceData release];
					
				} else {
					// no conversion necessary for Quartz to be able to use the data
					mipmapData = surfaceData;
					
				}
			}
			
			CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)mipmapData);
			[mipmapData release];
			
//			CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)pixelFormatInfo.colorSpaceName);
//			CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName((CFStringRef)(formatInfo.originalPixelFormat == TKPixelFormatUnknown ? pixelFormatInfo.colorSpaceName : TKPixelFormatInfoFromPixelFormat(formatInfo.originalPixelFormat).colorSpaceName));
			
//			CGColorSpaceRef colorSpace = NULL;
//			
//			if (pixelFormatInfo.colorSpaceName) {
//				colorSpace = CGColorSpaceCreateWithName((CFStringRef)pixelFormatInfo.colorSpaceName);
//			}
			
			CGColorSpaceRef colorSpace = TKCreateColorSpaceFromColorSpace(pixelFormatInfo.colorSpace);
			
			
			CGImageRef imageRef = CGImageCreate(mipmapWidth,
												mipmapHeight,
												pixelFormatInfo.bitsPerComponent,
												pixelFormatInfo.bitsPerPixel,
												((pixelFormatInfo.bitsPerPixel + 7)/8) * mipmapWidth,
												colorSpace,
												pixelFormatInfo.bitmapInfo,
												provider,
												NULL,
												false,
												kCGRenderingIntentDefault);
			CGColorSpaceRelease(colorSpace);
			CGDataProviderRelease(provider);
			
			if (imageRef == NULL) {
				NSLog(@"[%@ %@] CGImageCreate() (for faceIndex == %lu, mipmapIndex == %lu) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)faceIndex, (unsigned long)mipmapIndex);
				continue;
			}
			
			TKDDSImageRep *imageRep = [[TKDDSImageRep alloc] initWithCGImage:imageRef
																  sliceIndex:TKSliceIndexNone
																		face:(dds.isTextureCube() ? faceIndex : TKFaceNone)
																  frameIndex:TKFrameIndexNone
																 mipmapIndex:mipmapIndex];
			imageRep.format = formatInfo.format;
			imageRep.container = (dds.header.hasDX10Header() ? TKDDSContainerDX10 : TKDDSContainerDX9);
			
			CGImageAlphaInfo alphaInfo = (CGImageAlphaInfo)(pixelFormatInfo.bitmapInfo & kCGBitmapAlphaInfoMask);
			
			imageRep.imageProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:(pixelFormatInfo.bitmapInfo & kCGBitmapFloatComponents)],(id)kCGImagePropertyIsFloat,
										[NSNumber numberWithUnsignedInteger:imageRep.pixelsWide],kCGImagePropertyPixelWidth,
										[NSNumber numberWithUnsignedInteger:imageRep.pixelsHigh],kCGImagePropertyPixelHeight,
										[NSNumber numberWithUnsignedInteger:pixelFormatInfo.bitsPerComponent],kCGImagePropertyDepth,
										[NSNumber numberWithBool:TKHasAlpha(alphaInfo)],kCGImagePropertyHasAlpha,
										nil];
			
			CGImageRelease(imageRef);
			
			if (imageRep) [bitmapImageReps addObject:imageRep];
			
			[imageRep release];
			
			if (firstRepOnly && faceIndex == 0 && mipmapIndex == 0) {
				return [[bitmapImageReps copy] autorelease];
			}
			
		}
	}
	return [[bitmapImageReps copy] autorelease];
}


+ (id)imageRepWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] imageRepWithData:aData error:NULL];
}


+ (id)imageRepWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES error:outError];
	if ([imageReps count]) return [imageReps objectAtIndex:0];
	return nil;
}


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithData:aData error:NULL];
}


- (id)initWithData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *imageReps = [[self class] imageRepsWithData:aData firstRepresentationOnly:YES error:outError];
	if ((imageReps == nil) || !([imageReps count] > 0)) {
		[self release];
		return nil;
	}
	self = [[imageReps objectAtIndex:0] retain];
	return self;
}


- (id)copyWithZone:(NSZone *)zone {
	TKDDSImageRep *copy = (TKDDSImageRep *)[super copyWithZone:zone];
#if TK_DEBUG
	NSLog(@"[%@ %@] copy == %@, class == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), copy, NSStringFromClass([copy class]));
#endif
	return copy;
}


- (id)initWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super initWithCoder:coder])) {
		format = [[coder decodeObjectForKey:TKDDSFormatKey] unsignedIntegerValue];
		container = [[coder decodeObjectForKey:TKDDSContainerKey] unsignedIntegerValue];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super encodeWithCoder:coder];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:format] forKey:TKDDSFormatKey];
	[coder encodeObject:[NSNumber numberWithUnsignedInteger:container] forKey:TKDDSContainerKey];
}


#pragma mark - writing

+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[self class] DDSRepresentationOfImageRepsInArray:tkImageReps usingFormat:[[self class] defaultFormat] quality:[TKImageRep defaultDXTCompressionQuality] container:[[self class] defaultContainer] options:options error:outError];
}


+ (NSData *)DDSRepresentationOfImageRepsInArray:(NSArray *)tkImageReps usingFormat:(TKDDSFormat)format quality:(TKDXTCompressionQuality)aQuality container:(TKDDSContainer)container options:(NSDictionary *)options error:(NSError **)outError {
#if TK_DEBUG
//	NSLog(@"[%@ %@] tkImageReps == %@, options == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tkImageReps, options);
//	NSLog(@"[%@ %@] format == %@, options == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [[self class] localizedNameOfFormat:format], options);
#endif
	NSParameterAssert([tkImageReps count] > 0);
	
	// outError isn't implemented yet, so set it to nil in case it's tried to be used if we return nil
	if (outError) *outError = nil;
	
	if (([[self class] operationMaskForFormat:format] & TKDDSOperationDX9Write) != TKDDSOperationDX9Write &&
		([[self class] operationMaskForFormat:format] & TKDDSOperationDX10Write) != TKDDSOperationDX10Write) {
		[[self class] raiseUnsupportedFormatExceptionWithDDSFormat:format];
	}
	
	TKDDSOperation operation = TKDDSOperationNone;
	if (container == TKDDSContainerDX9) operation = TKDDSOperationDX9Write;
	else if (container == TKDDSContainerDX10) operation = TKDDSOperationDX10Write;
	
	if (([[self class] operationMaskForFormat:format] & operation) != operation) {
		[[self class] raiseUnsupportedContainerAndFormatCombinationExceptionWithDDSFormat:format container:container];
	}
	
//	BOOL hasDimensionsThatArePowerOfTwo = YES;
	
	NSMutableArray *revisedImageReps = [NSMutableArray array];
	
	for (NSImageRep *imageRep in tkImageReps) {
		if ([imageRep isKindOfClass:[TKImageRep class]]) {
			[revisedImageReps addObject:imageRep];
//			hasDimensionsThatArePowerOfTwo = hasDimensionsThatArePowerOfTwo && [(TKImageRep *)imageRep hasDimensionsThatArePowerOfTwo];
		} else {
			NSLog(@"[%@ %@] imageRep (%@) is NOT a TKImageRep!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRep);
		}
	}
	
	NSNumber *nMipmapType = [options objectForKey:TKImageMipmapGenerationKey];
	NSNumber *nWrapMode = [options objectForKey:TKImageWrapModeKey];
	NSNumber *nResizeMode = [options objectForKey:TKImageResizeModeKey];
//	NSNumber *nResizeFilter = [options objectForKey:TKImageResizeFilterKey];
	
	NSUInteger maxWidth = 0;
	NSUInteger maxHeight = 0;
	
//	NSUInteger sliceCount = 1;
	NSUInteger faceCount = 1;
	
	NSUInteger highestFaceIndex = 0;
	
	for (TKImageRep *imageRep in revisedImageReps) {
		maxWidth = MAX(imageRep.pixelsWide, maxWidth);
		maxHeight = MAX(imageRep.pixelsHigh, maxHeight);
		
		if (imageRep.face != TKFaceNone) highestFaceIndex = MAX(imageRep.face, highestFaceIndex);
 	}
	
	if (highestFaceIndex > 0) faceCount = highestFaceIndex + 1;
	
	TKDDSFormatInfo formatInfo = TKDDSFormatInfoFromDDSFormat(format);
	TKDDSFormatCreationInfo creationInfo = formatInfo.creationInfo;
	
	InputOptions inputOptions;
	
	inputOptions.setTextureLayout((faceCount == 1 ? TextureType_2D : TextureType_Cube), maxWidth, maxHeight);
	inputOptions.setFormat(creationInfo.ddsInputFormat);
	inputOptions.setNormalMap(false);
	inputOptions.setConvertToNormalMap(false);
	inputOptions.setGamma(2.2, 2.2);
	
	inputOptions.setWrapMode(TKWrapModeInfoFromWrapMode([nWrapMode unsignedIntegerValue]).ddsWrapMode);
	inputOptions.setRoundMode(TKResizeModeInfoFromResizeMode([nResizeMode unsignedIntegerValue]).ddsRoundMode);
	
	if (nMipmapType == nil || [nMipmapType unsignedIntegerValue] == TKMipmapGenerationNoMipmaps) {
		inputOptions.setMipmapGeneration(false);
	} else {
		inputOptions.setMipmapGeneration(true);
		inputOptions.setMipmapFilter(TKMipmapGenerationTypeInfoFromMipmapGenerationType([nMipmapType unsignedIntegerValue]).ddsMipmapFilter);
		inputOptions.setNormalizeMipmaps(true);
	}
	
	for (TKImageRep *imageRep in revisedImageReps) {
		
		inputOptions.setAlphaMode(AlphaModeFromCGAlphaInfo(imageRep.alphaInfo));
		
		NSData *mipmapData = imageRep.data;
		
		if (imageRep.pixelFormat != creationInfo.inputPixelFormat) {
//			mipmapData = [imageRep dataByConvertingToPixelFormat:creationInfo.inputPixelFormat];
			mipmapData = [imageRep dataByConvertingToPixelFormat:creationInfo.inputPixelFormat options:TKPixelFormatConversionUseColorManagement];
		}
		
		if (!inputOptions.setMipmapData([mipmapData bytes], imageRep.pixelsWide, imageRep.pixelsHigh, 1, (imageRep.face == TKFaceNone ? 0 : imageRep.face), imageRep.mipmapIndex)) {
			NSLog(@"[%@ %@] failed to inputOptions.setMipmapData() for face == %lu, mipmapIndex == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)imageRep.face, (unsigned long)imageRep.mipmapIndex);
			
		}
		
	}
	
	CompressionOptions compressionOptions;
	compressionOptions.setQuality(TKDXTCompressionQualityInfoFromDXTCompressionQuality(aQuality).ddsQuality);
	compressionOptions.setFormat(creationInfo.ddsFormat);
	compressionOptions.setPixelType(creationInfo.ddsPixelType);
	
	if (creationInfo.ddsFormat == Format_RGBA) {
		if (creationInfo.bitCount) {
			if (container == TKDDSContainerDX10) {
				compressionOptions.setPixelFormat(creationInfo.rsize, creationInfo.gsize, creationInfo.bsize, creationInfo.asize);
			} else {
				compressionOptions.setPixelFormat(creationInfo.bitCount, creationInfo.rmask, creationInfo.gmask, creationInfo.bmask, creationInfo.amask);
			}
		} else {
			compressionOptions.setPixelFormat(creationInfo.rsize, creationInfo.gsize, creationInfo.bsize, creationInfo.asize);
		}
	}
	
	NSMutableData *ddsData = [[NSMutableData alloc] init];
	
	TKOutputHandler outputHandler(ddsData);
	TKErrorHandler errorHandler;
	
	Container ddsContainer = Container_DDS;
	if (container == TKDDSContainerDX9) ddsContainer = Container_DDS;
	else if (container == TKDDSContainerDX10) ddsContainer = Container_DDS10;
	
	
	OutputOptions outputOptions;
	outputOptions.setOutputHeader(true);
	outputOptions.setContainer(ddsContainer);
	outputOptions.setOutputHandler(&outputHandler);
	outputOptions.setErrorHandler(&errorHandler);
	
	
	Context context;
	context.enableCudaAcceleration(false);
	
	if (!context.process(inputOptions, compressionOptions, outputOptions)) {
		NSLog(@"[%@ %@] context.process() returned false!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		
		const Error error = errorHandler.getError();
		
		NSLog(@"[%@ %@] errorHandler.getError() == %u, nvtt::errorString() == %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error, errorString(error));
		NSLog(@"[%@ %@] ddsData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[ddsData length]);
		
		if (outError) {
			NSDictionary *userInfo = nil;
			
			const char *nvErrorString = nvtt::errorString(error);
			
			if (nvErrorString) {
				userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s", nvErrorString], NSLocalizedDescriptionKey, nil];
			}
			// TODO: better error code
			*outError = [NSError errorWithDomain:TKErrorDomain code:TKErrorUnknown userInfo:userInfo];
		}
		
		[ddsData release];
		return nil;
	}
	
#if TK_DEBUG
//	NSLog(@"[%@ %@] ddsData length == %lu", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[ddsData length]);
#endif
	
	NSData *copiedData = [ddsData copy];
	[ddsData release];
	return [copiedData autorelease];
}


#pragma mark - resizing


+ (TKImageRep *)imageRepByResizingImageRep:(TKImageRep *)imageRep usingResizeMode:(TKResizeMode)resizeMode resizeFilter:(TKResizeFilter)resizeFilter {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(imageRep != nil);
	NSParameterAssert(resizeMode < TKResizeModeInfoTableCount);
	NSParameterAssert(resizeFilter < TKResizeFilterInfoTableCount);
	
	TKResizingInfo resizingInfo = TKResizingInfoFromPixelFormat(imageRep.pixelFormat);
	
	NSData *mipmapData = imageRep.data;
	
	if (imageRep.pixelFormat != resizingInfo.outputPixelFormat) {
		// need to convert it to an input format that NVTT understands
//		mipmapData = [imageRep dataByConvertingToPixelFormat:resizingInfo.outputPixelFormat];
		mipmapData = [imageRep dataByConvertingToPixelFormat:resizingInfo.outputPixelFormat options:TKPixelFormatConversionOptionsDefault];
	}
	
	NSAssert(mipmapData != nil, @"mipmapData != nil");
	
	Surface surface;
	
	surface.setAlphaMode(resizingInfo.ddsAlphaMode);
	
	if (!surface.setImage(resizingInfo.ddsInputFormat, imageRep.pixelsWide, imageRep.pixelsHigh, 1, [mipmapData bytes])) {
		NSLog(@"[%@ %@] ERROR: surface.setImage() failed!, imageRep == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRep);
		return nil;
	}
	
	surface.resize(-1, TKResizeModeInfoFromResizeMode(resizeMode).ddsRoundMode, TKResizeFilterInfoFromResizeFilter(resizeFilter).ddsResizeFilter);
	
	const NSUInteger pixelCount = surface.width() * surface.height();
	
	// `nvtt::Surface` stores data in 32F planar format, so we need to create an interleaved copy
	
	float *dest = (float *)calloc(surface.width() * surface.height() * surface.depth(), sizeof(float) * 4);
	if (dest == NULL) {
		NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return nil;
	}
	
	const float *rChannel = surface.channel(0);
	const float *gChannel = surface.channel(1);
	const float *bChannel = surface.channel(2);
	const float *aChannel = surface.channel(3);
	
	for (NSUInteger i = 0; i < pixelCount; i++) {
		dest[4 * i + 0] = rChannel[i];
		dest[4 * i + 1] = gChannel[i];
		dest[4 * i + 2] = bChannel[i];
		dest[4 * i + 3] = aChannel[i];
	}
	
	NSData *surfaceData = [[NSData alloc] initWithBytes:dest length:surface.width() * surface.height() * surface.depth() * sizeof(float) * 4];
	
	free(dest);
	
	// now we need to convert the 32F (32 bpc) data back to the original pixel format
	
//	NSData *originalPixelFormatData = [[self class] dataByConvertingData:surfaceData inFormat:TKPixelFormatRGBA32323232F toFormat:imageRep.pixelFormat pixelCount:pixelCount ignoreAlpha:NO];
	NSData *originalPixelFormatData = [[self class] dataByConvertingData:surfaceData inFormat:TKPixelFormatRGBA32323232F toFormat:imageRep.pixelFormat pixelCount:pixelCount options:TKPixelFormatConversionOptionsDefault];
	
	[surfaceData release];
	
	Class originalImageRepClass = [imageRep class];
	
	TKImageRep *resizedImageRep = [[originalImageRepClass alloc] initWithPixelData:originalPixelFormatData
																	   pixelFormat:imageRep.pixelFormat
																		pixelsWide:surface.width()
																		pixelsHigh:surface.height()
																		sliceIndex:imageRep.sliceIndex
																			  face:imageRep.face
																		frameIndex:imageRep.frameIndex
																	   mipmapIndex:imageRep.mipmapIndex];
	
	if ([resizedImageRep isKindOfClass:[TKDDSImageRep class]]) {
		[(TKDDSImageRep *)resizedImageRep setFormat:[(TKDDSImageRep *)imageRep format]];
		[(TKDDSImageRep *)resizedImageRep setContainer:[(TKDDSImageRep *)imageRep container]];
		
	} else if ([resizedImageRep isKindOfClass:[TKVTFImageRep class]]) {
		[(TKVTFImageRep *)resizedImageRep setFormat:[(TKVTFImageRep *)imageRep format]];
		
	}
	
	// update image properties (kCGImagePropertyPixelWidth and kCGImagePropertyPixelHeight)
	// TODO: update EXIF and other properties as well
	
	NSMutableDictionary *mImageProperties = [[imageRep.imageProperties mutableCopy] autorelease];
	[mImageProperties setObject:[NSNumber numberWithUnsignedInteger:resizedImageRep.pixelsWide] forKey:(id)kCGImagePropertyPixelWidth];
	[mImageProperties setObject:[NSNumber numberWithUnsignedInteger:resizedImageRep.pixelsHigh] forKey:(id)kCGImagePropertyPixelHeight];
	
	resizedImageRep.imageProperties = mImageProperties;
	
	return [resizedImageRep autorelease];
}


#pragma mark - mipmap generation

+ (NSArray *)mipmapImageRepsOfImageRep:(TKImageRep *)imageRep usingFilter:(TKMipmapGenerationType)filterType {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSParameterAssert(imageRep != nil);
	NSParameterAssert(filterType != TKMipmapGenerationNoMipmaps && filterType < TKMipmapGenerationTypeInfoTableCount);
	
	TKResizingInfo resizingInfo = TKResizingInfoFromPixelFormat(imageRep.pixelFormat);
	
	NSData *mipmapData = imageRep.data;
	
	if (imageRep.pixelFormat != resizingInfo.outputPixelFormat) {
		// need to convert it to an input format that NVTT understands
//		mipmapData = [imageRep dataByConvertingToPixelFormat:resizingInfo.outputPixelFormat];
		mipmapData = [imageRep dataByConvertingToPixelFormat:resizingInfo.outputPixelFormat options:TKPixelFormatConversionOptionsDefault];
	}
	
	NSAssert(mipmapData != nil, @"mipmapData != nil");
	
	Surface surface;
	
	surface.setAlphaMode(resizingInfo.ddsAlphaMode);
	
	if (!surface.setImage(resizingInfo.ddsInputFormat, imageRep.pixelsWide, imageRep.pixelsHigh, 1, [mipmapData bytes])) {
		NSLog(@"[%@ %@] ERROR: surface.setImage() failed!, imageRep == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), imageRep);
		return nil;
	}
	
	NSMutableArray *mipmapImageReps = [NSMutableArray array];
	
	NSUInteger mipmapIndex = 0;
	
	while (surface.buildNextMipmap(TKMipmapGenerationTypeInfoFromMipmapGenerationType(filterType).ddsMipmapFilter)) {
		
		mipmapIndex++;
		
		const NSUInteger pixelCount = surface.width() * surface.height();
		
		// `nvtt::Surface` stores data in 32F planar format, so we need to create an interleaved copy
		
		float *dest = (float *)calloc(surface.width() * surface.height() * surface.depth(), sizeof(float) * 4);
		if (dest == NULL) {
			NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			continue;
		}
		
		const float *rChannel = surface.channel(0);
		const float *gChannel = surface.channel(1);
		const float *bChannel = surface.channel(2);
		const float *aChannel = surface.channel(3);
		
		for (NSUInteger i = 0; i < pixelCount; i++) {
			dest[4 * i + 0] = rChannel[i];
			dest[4 * i + 1] = gChannel[i];
			dest[4 * i + 2] = bChannel[i];
			dest[4 * i + 3] = aChannel[i];
		}
		
		NSData *surfaceData = [[NSData alloc] initWithBytes:dest length:surface.width() * surface.height() * surface.depth() * sizeof(float) * 4];
		
		free(dest);
		
		// now we need to convert the 32F (32 bpc) data back to the original pixel format
		
//		NSData *originalPixelFormatData = [[self class] dataByConvertingData:surfaceData inFormat:TKPixelFormatRGBA32323232F toFormat:imageRep.pixelFormat pixelCount:pixelCount ignoreAlpha:NO];
		NSData *originalPixelFormatData = [[self class] dataByConvertingData:surfaceData inFormat:TKPixelFormatRGBA32323232F toFormat:imageRep.pixelFormat pixelCount:pixelCount options:TKPixelFormatConversionOptionsDefault];
		
		[surfaceData release];
		
		Class originalImageRepClass = [imageRep class];
		
		TKImageRep *mipmapImageRep = [[originalImageRepClass alloc] initWithPixelData:originalPixelFormatData
																		  pixelFormat:imageRep.pixelFormat
																		   pixelsWide:surface.width()
																		   pixelsHigh:surface.height()
																		   sliceIndex:imageRep.sliceIndex
																				 face:imageRep.face
																		   frameIndex:imageRep.frameIndex
																		  mipmapIndex:mipmapIndex];
		
		if ([mipmapImageRep isKindOfClass:[TKDDSImageRep class]]) {
			[(TKDDSImageRep *)mipmapImageRep setFormat:[(TKDDSImageRep *)imageRep format]];
			[(TKDDSImageRep *)mipmapImageRep setContainer:[(TKDDSImageRep *)imageRep container]];
			
		} else if ([mipmapImageRep isKindOfClass:[TKVTFImageRep class]]) {
			[(TKVTFImageRep *)mipmapImageRep setFormat:[(TKVTFImageRep *)imageRep format]];
			
		}
		
		// update image properties (kCGImagePropertyPixelWidth and kCGImagePropertyPixelHeight)
		
		NSMutableDictionary *mImageProperties = [[imageRep.imageProperties mutableCopy] autorelease];
		[mImageProperties setObject:[NSNumber numberWithUnsignedInteger:mipmapImageRep.pixelsWide] forKey:(id)kCGImagePropertyPixelWidth];
		[mImageProperties setObject:[NSNumber numberWithUnsignedInteger:mipmapImageRep.pixelsHigh] forKey:(id)kCGImagePropertyPixelHeight];
		
		mipmapImageRep.imageProperties = mImageProperties;
		
		if (mipmapImageRep) [mipmapImageReps addObject:mipmapImageRep];
		
		[mipmapImageRep release];
	}
	return mipmapImageReps;
}


#pragma mark - data conversion


template<typename S, typename D>
static NSData *TKImageDataConvertIntegerToIntegerTemplated(NSData *inputData, TKPixelFormatInfo inInfo, TKPixelFormatInfo outInfo, NSUInteger pixelCount) {
#if TK_DEBUG
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	const S *src = (const S *)[inputData bytes];
	
	D *dest = (D *)calloc(pixelCount, outInfo.bytesPerPixel);
	if (dest == NULL) {
		NSLog(@"calloc() failed!");
		return nil;
	}
	
//	BOOL needToUnpremultiplyAlpha = TKIsPremultiplied(inInfo.bitmapInfo) && !TKIsPremultiplied(outInfo.bitmapInfo);
//	
//	BOOL needToPremultiplyAlpha = TKIsPremultiplied(outInfo.bitmapInfo);
//	
	
	for (NSUInteger i = 0; i < pixelCount; i++) {
		if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
			// is this a color to grayscale conversion?
			
			
			
			dest[outInfo.componentCount * i + outInfo.rIndex] = PixelFormat::convert(src[inInfo.componentCount * i + inInfo.rIndex], inInfo.bitsPerComponent, outInfo.bitsPerComponent);
		}
		
		if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
			dest[outInfo.componentCount * i + outInfo.gIndex] = PixelFormat::convert(src[inInfo.componentCount * i + inInfo.gIndex], inInfo.bitsPerComponent, outInfo.bitsPerComponent);
		}
		
		if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
			dest[outInfo.componentCount * i + outInfo.bIndex] = PixelFormat::convert(src[inInfo.componentCount * i + inInfo.bIndex], inInfo.bitsPerComponent, outInfo.bitsPerComponent);
		} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
			// we're assuming unsigned 
			dest[outInfo.componentCount * i + outInfo.bIndex] = (D)0xffffffff;
		}
		
		if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
			dest[outInfo.componentCount * i + outInfo.aIndex] = PixelFormat::convert(src[inInfo.componentCount * i + inInfo.aIndex], inInfo.bitsPerComponent, outInfo.bitsPerComponent);
		} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
			// we're assuming unsigned 
			dest[outInfo.componentCount * i + outInfo.aIndex] = (D)0xffffffff;
		}
	}
	
	NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
	free(dest);
	return outputData;
}


// adapted from ::toSrgb() and ::fromSrgb() in NVTextureTools/nvtt/Surface.cpp:

typedef float (*TKColorManagementProc)(float f);


static float TKLinearToSRGB(float f) {
    if (isnan(f))               f = 0.0f;
    else if (f <= 0.0f)         f = 0.0f;
    else if (f <= 0.0031308f)   f = 12.92f * f;
    else if (f <= 1.0f)         f = (powf(f, 0.41666f) * 1.055f) - 0.055f;
    else                        f = 1.0f;
    return f;
}

static float TKSRGBToLinear(float f) {
    if (f < 0.0f)           f = 0.0f;
    else if (f < 0.04045f)  f = f / 12.92f;
    else if (f <= 1.0f)     f = powf((f + 0.055f) / 1.055f, 2.4f);
    else                    f = 1.0f;
    return f;
}


template<typename S, typename D>
static NSData *TKImageDataConvertFloatToIntegerTemplated(NSData *inputData, TKPixelFormatInfo inInfo, TKPixelFormatInfo outInfo, NSUInteger pixelCount, float floatClampMax, int intClampMax, TKColorManagementProc colManProc) {
#if TK_DEBUG
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	
	const S *src = (const S *)[inputData bytes];
	
	D *dest = (D *)calloc(pixelCount, outInfo.bytesPerPixel);
	if (dest == NULL) {
		NSLog(@"calloc() failed!");
		return nil;
	}
	
	for (NSUInteger i = 0; i < pixelCount; i++) {
		if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
			const float R = (colManProc ? colManProc(src[inInfo.componentCount * i + inInfo.rIndex]) : src[inInfo.componentCount * i + inInfo.rIndex]);
			dest[outInfo.componentCount * i + outInfo.rIndex] = nv::clamp(int(floatClampMax * R), 0, intClampMax);
		}
		
		if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
			const float G = (colManProc ? colManProc(src[inInfo.componentCount * i + inInfo.gIndex]) : src[inInfo.componentCount * i + inInfo.gIndex]);
			dest[outInfo.componentCount * i + outInfo.gIndex] = nv::clamp(int(floatClampMax * G), 0, intClampMax);
		}
		
		if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
			const float B = (colManProc ? colManProc(src[inInfo.componentCount * i + inInfo.bIndex]) : src[inInfo.componentCount * i + inInfo.bIndex]);
			dest[outInfo.componentCount * i + outInfo.bIndex] = nv::clamp(int(floatClampMax * B), 0, intClampMax);
			
		} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
			// we're assuming unsigned 
			dest[outInfo.componentCount * i + outInfo.bIndex] = (D)0xffffffff;
		}
		
		if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
			dest[outInfo.componentCount * i + outInfo.aIndex] = nv::clamp(int(floatClampMax * src[inInfo.componentCount * i + inInfo.aIndex]), 0, intClampMax);
		} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
			// we're assuming unsigned 
			dest[outInfo.componentCount * i + outInfo.aIndex] = (D)0xffffffff;
		}
	}
	
	NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
	free(dest);
	return outputData;
}



template<typename S, typename D>
static NSData *TKImageDataConvertIntegerToFloatTemplated(NSData *inputData, TKPixelFormatInfo inInfo, TKPixelFormatInfo outInfo, NSUInteger pixelCount, float denominator, TKColorManagementProc colManProc) {
#if TK_DEBUG
	NSLog(@"%s", __PRETTY_FUNCTION__);
#endif	
	const S *src = (const S *)[inputData bytes];
	
	D *dest = (D *)calloc(pixelCount, outInfo.bytesPerPixel);
	if (dest == NULL) {
		NSLog(@"calloc() failed!");
		return nil;
	}
	
	if (outInfo.bitsPerComponent == 16) {
		
		const float normalizedFloatMax = 1.0f;
		const uint16 normalizedHalfMax = half_from_float(*(uint32 *)&normalizedFloatMax);
		
		for (NSUInteger i = 0; i < pixelCount; i++) {
			
			if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
				const float R = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.rIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.rIndex]) / denominator);
				dest[outInfo.componentCount * i + outInfo.rIndex] = half_from_float(*(uint32 *)&R);
			}
			
			if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
				const float G = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.gIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.gIndex]) / denominator);
				dest[outInfo.componentCount * i + outInfo.gIndex] = half_from_float(*(uint32 *)&G);
			}
			
			if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
				const float B = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.bIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.bIndex]) / denominator);
				dest[outInfo.componentCount * i + outInfo.bIndex] = half_from_float(*(uint32 *)&B);
			} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.bIndex] = normalizedHalfMax;
			}
			
			if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
				const float A = float(src[inInfo.componentCount * i + inInfo.aIndex]) / denominator;
				dest[outInfo.componentCount * i + outInfo.aIndex] = half_from_float(*(uint32 *)&A);
			} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.aIndex] = normalizedHalfMax;
			}
		}
		
	} else if (outInfo.bitsPerComponent == 32) {
		
		for (NSUInteger i = 0; i < pixelCount; i++) {
			if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.rIndex] = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.rIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.rIndex]) / denominator);
			}
			
			if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.gIndex] = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.gIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.gIndex]) / denominator);
			}
			
			if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.bIndex] = (colManProc ? colManProc(float(src[inInfo.componentCount * i + inInfo.bIndex]) / denominator) : float(src[inInfo.componentCount * i + inInfo.bIndex]) / denominator);
			} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.bIndex] = 1.0f;
			}
			
			if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.aIndex] = float(src[inInfo.componentCount * i + inInfo.aIndex]) / denominator;
			} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
				dest[outInfo.componentCount * i + outInfo.aIndex] = 1.0f;
			}
		}
	}
	
	NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
	free(dest);
	return outputData;
}



// DONE: use templates or otherwise further simplify this
// TODO: Use vImage.framework for potentially improved performance 
// TODO: Use ColorSync.framework and ColorSyncTransforms for 


+ (NSData *)dataByConvertingData:(NSData *)inputData inFormat:(TKPixelFormat)inputPixelFormat toFormat:(TKPixelFormat)outputPixelFormat pixelCount:(NSUInteger)pixelCount options:(TKPixelFormatConversionOptions)options {
#if TK_DEBUG
    NSLog(@"[%@ %@] %@   --->   %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), TKStringFromPixelFormat(inputPixelFormat), TKStringFromPixelFormat(outputPixelFormat));
#endif
	if (inputPixelFormat == outputPixelFormat) return inputData;
	
	NSParameterAssert(inputPixelFormat > TKPixelFormatXBGR1555 && inputPixelFormat < TKPixelFormatInfoTableCount);
	NSParameterAssert(outputPixelFormat > TKPixelFormatXBGR1555 && outputPixelFormat < TKPixelFormatInfoTableCount);
	
	TKPixelFormatInfo inInfo = TKPixelFormatInfoFromPixelFormat(inputPixelFormat);
	TKPixelFormatInfo outInfo = TKPixelFormatInfoFromPixelFormat(outputPixelFormat);
	
	const void *srcBytes = [inputData bytes];
	
	if (inInfo.bitmapInfo & kCGBitmapFloatComponents && outInfo.bitmapInfo & kCGBitmapFloatComponents) {
		
#pragma mark FLOAT to FLOAT
		
		// both SRC and DEST are float
		// we're (only) handling:
		//	16F	->	32F
		//	32F	->	16F
		//	32F	->	32F
		
		if (inInfo.bitsPerComponent == 16 && outInfo.bitsPerComponent == 32) {
			
			uint32 *dest = (uint32 *)calloc(pixelCount, outInfo.bytesPerPixel);
			if (dest == NULL) {
				NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return nil;
			}
			
			const uint16 *src = (const uint16 *)srcBytes;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				
				if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.rIndex] = half_to_float(src[inInfo.componentCount * i + inInfo.rIndex]);
				}
				
				if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.gIndex] = half_to_float(src[inInfo.componentCount * i + inInfo.gIndex]);
				}
				
				if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.bIndex] = half_to_float(src[inInfo.componentCount * i + inInfo.bIndex]);
				} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
					((float *)dest)[outInfo.componentCount * i + outInfo.bIndex] = 1.0f;
				}
				
				if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
					
					/* Not sure what the deal is with this. Many "official" RGBA16161616F VTF files I've tested have 0 for the A channel,
					 which can hardly be intended. In VTF, anyway, it appears to be treated more like RGBX16161616F, so we'll set to 1.0f for the time being. */
					/* Update: I've also found numerous "official" RGBA16161616F VTF files that have "junk" values in the alpha channel, including non-normalized values,
					 negative values, NaN, etc. Will try just ignoring all alpha channel values for now by setting to 1.0f, if the `TKPixelFormatConversionIgnoreAlpha` flag is true. */
					
					if (options & TKPixelFormatConversionIgnoreAlpha) {
						((float *)dest)[outInfo.componentCount * i + outInfo.aIndex] = 1.0f;
						
					} else {
						dest[outInfo.componentCount * i + outInfo.aIndex] = half_to_float(src[inInfo.componentCount * i + inInfo.aIndex]);
						
					}
				} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
					((float *)dest)[outInfo.componentCount * i + outInfo.aIndex] = 1.0f;
				}
			}
			
			NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
			free(dest);
			return outputData;
			
			
		} else if (inInfo.bitsPerComponent == 32 && outInfo.bitsPerComponent == 16) {
			
			uint16 *dest = (uint16 *)calloc(pixelCount, outInfo.bytesPerPixel);
			if (dest == NULL) {
				NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return nil;
			}
			
			const uint32 *src = (const uint32 *)srcBytes;
			
			const float normalizedFloatMax = 1.0f;
			const uint16 normalizedHalfMax = half_from_float(*(uint32 *)&normalizedFloatMax);
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				
				if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.rIndex] = half_from_float(src[inInfo.componentCount * i + inInfo.rIndex]);
				}
				
				if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.gIndex] = half_from_float(src[inInfo.componentCount * i + inInfo.gIndex]);
				}
				
				if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.bIndex] = half_from_float(src[inInfo.componentCount * i + inInfo.bIndex]);
				} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.bIndex] = normalizedHalfMax;
				}
				
				if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.aIndex] = half_from_float(src[inInfo.componentCount * i + inInfo.aIndex]);
				} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.aIndex] = normalizedHalfMax;
				}
			}
			
			NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
			free(dest);
			return outputData;
			
			
		} else if (inInfo.bitsPerComponent == 32 && outInfo.bitsPerComponent == 32) {
			
			float *dest = (float *)calloc(pixelCount, outInfo.bytesPerPixel);
			if (dest == NULL) {
				NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return nil;
			}
			
			const float *src = (const float *)srcBytes;
			
			for (NSUInteger i = 0; i < pixelCount; i++) {
				
				if (inInfo.rIndex > -1 && outInfo.rIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.rIndex] = src[inInfo.componentCount * i + inInfo.rIndex];
				}
				
				if (inInfo.gIndex > -1 && outInfo.gIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.gIndex] = src[inInfo.componentCount * i + inInfo.gIndex];
				}
				
				if (inInfo.bIndex > -1 && outInfo.bIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.bIndex] = src[inInfo.componentCount * i + inInfo.bIndex];
				} else if (inInfo.bIndex == -1 && outInfo.bIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.bIndex] = 1.0f;
				}
				
				if (inInfo.aIndex > -1 && outInfo.aIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.aIndex] = src[inInfo.componentCount * i + inInfo.aIndex];
				} else if (inInfo.aIndex == -1 && outInfo.aIndex > -1) {
					dest[outInfo.componentCount * i + outInfo.aIndex] = 1.0f;
				}
				
			}
			
			NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
			free(dest);
			return outputData;
			
		}
		
	} else if (inInfo.bitmapInfo & kCGBitmapFloatComponents && (outInfo.bitmapInfo & kCGBitmapFloatComponents) == 0) {
		
#pragma mark FLOAT to INT
		
		// SRC is float, DEST is integer
		// we're (only) handling:
		//	32F	->	8
		//	32F	->	16
		
		TKColorManagementProc colorManagementProc = (options & TKPixelFormatConversionUseColorManagement ? TKLinearToSRGB : NULL);
		
		if (outInfo.bitsPerComponent == 8) {
			
			return TKImageDataConvertFloatToIntegerTemplated<float, uint8>(inputData, inInfo, outInfo, pixelCount, 255.0f, 255, colorManagementProc);
			
		} else if (outInfo.bitsPerComponent == 16) {
			
			return TKImageDataConvertFloatToIntegerTemplated<float, uint16>(inputData, inInfo, outInfo, pixelCount, 65535.0f, 65535, colorManagementProc);
		}
		
		
	} else if ((inInfo.bitmapInfo & kCGBitmapFloatComponents) == 0 && outInfo.bitmapInfo & kCGBitmapFloatComponents) {
		
#pragma mark INT to FLOAT
		
		// SRC is integer, DEST is float
		// we're handling:
		//	8	->	16F
		//	16	->	16F
		//	8	->	32F
		//	16	->	32F
		
		TKColorManagementProc colorManagementProc = (options & TKPixelFormatConversionUseColorManagement ? TKSRGBToLinear : NULL);
		
		if (outInfo.bitsPerComponent == 16) {
			
			if (inInfo.bitsPerComponent == 8) {
				
				return TKImageDataConvertIntegerToFloatTemplated<uint8, uint16>(inputData, inInfo, outInfo, pixelCount, 255.0f, colorManagementProc);
				
			} else if (inInfo.bitsPerComponent == 16) {
				
				return TKImageDataConvertIntegerToFloatTemplated<uint16, uint16>(inputData, inInfo, outInfo, pixelCount, 65535.0f, colorManagementProc);
				
			}
		} else if (outInfo.bitsPerComponent == 32) {
			
			if (inInfo.bitsPerComponent == 8) {
				
				return TKImageDataConvertIntegerToFloatTemplated<uint8, float>(inputData, inInfo, outInfo, pixelCount, 255.0f, colorManagementProc);
				
			} else if (inInfo.bitsPerComponent == 16) {
				
				return TKImageDataConvertIntegerToFloatTemplated<uint16, float>(inputData, inInfo, outInfo, pixelCount, 65535.0f, colorManagementProc);
				
			}
		}
		
	} else {
		
#pragma mark INT to INT
		
		// both SRC and DEST are integer
		
		if (inInfo.bitsPerComponent == 8 && outInfo.bitsPerComponent == 8) {
			
			return TKImageDataConvertIntegerToIntegerTemplated<uint8, uint8>(inputData, inInfo, outInfo, pixelCount);
			
		} else if (inInfo.bitsPerComponent == 8 && outInfo.bitsPerComponent == 16) {
			
			return TKImageDataConvertIntegerToIntegerTemplated<uint8, uint16>(inputData, inInfo, outInfo, pixelCount);
			
		} else if (inInfo.bitsPerComponent == 16 && outInfo.bitsPerComponent == 8) {
			
			return TKImageDataConvertIntegerToIntegerTemplated<uint16, uint8>(inputData, inInfo, outInfo, pixelCount);
			
		} else if (inInfo.bitsPerComponent == 16 && outInfo.bitsPerComponent == 16) {
			
			return TKImageDataConvertIntegerToIntegerTemplated<uint16, uint16>(inputData, inInfo, outInfo, pixelCount);
			
		} else {
			
			void *destBytes = calloc(pixelCount, outInfo.bytesPerPixel);
			if (destBytes == NULL) {
				NSLog(@"[%@ %@] calloc() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
				return nil;
			}
			
			if (inInfo.bitsPerComponent == 10 && outInfo.bitsPerComponent == 16) {
				// TKPixelFormatRGBA1010102 to TKPixelFormatRGBA16161616 and TKPixelFormatBGRA1010102 to TKPixelFormatRGBA16161616
				
				const uint32 *src = (const uint32 *)srcBytes;
				uint16 *dest = (uint16 *)destBytes;
				
				TKDDSFormatInfo formatInfo = TKDDSFormatInfoFromDDSFormat((inputPixelFormat == TKPixelFormatRGBA1010102 ? TKDDSFormatRGBA1010102 : TKDDSFormatBGRA1010102));
				
				uint rshift, rsize;
				uint gshift, gsize;
				uint bshift, bsize;
				uint ashift, asize;
				
				nv::PixelFormat::maskShiftAndSize(formatInfo.creationInfo.rmask, &rshift, &rsize);
				nv::PixelFormat::maskShiftAndSize(formatInfo.creationInfo.gmask, &gshift, &gsize);
				nv::PixelFormat::maskShiftAndSize(formatInfo.creationInfo.bmask, &bshift, &bsize);
				nv::PixelFormat::maskShiftAndSize(formatInfo.creationInfo.amask, &ashift, &asize);
				
				for (NSUInteger i = 0; i < pixelCount; i++) {
					dest[outInfo.componentCount * i + outInfo.rIndex] = PixelFormat::convert((src[i] & formatInfo.creationInfo.rmask) >> rshift, rsize, outInfo.bitsPerComponent);
					dest[outInfo.componentCount * i + outInfo.gIndex] = PixelFormat::convert((src[i] & formatInfo.creationInfo.gmask) >> gshift, gsize, outInfo.bitsPerComponent);
					dest[outInfo.componentCount * i + outInfo.bIndex] = PixelFormat::convert((src[i] & formatInfo.creationInfo.bmask) >> bshift, bsize, outInfo.bitsPerComponent);
					dest[outInfo.componentCount * i + outInfo.aIndex] = PixelFormat::convert((src[i] & formatInfo.creationInfo.amask) >> ashift, asize, outInfo.bitsPerComponent);
				}
				
				NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
				free(dest);
				return outputData;
				
			} else if (inInfo.bitsPerComponent == 4) {
				
				// TKPixelFormatLA44 to TKPixelFormatLA
				
				uint8 *dest = (uint8 *)destBytes;
				
				const uint8 *src = (const uint8 *)srcBytes;
				
				for (NSUInteger i = 0; i < pixelCount; i++) {
					dest[outInfo.componentCount * i + 0] = PixelFormat::convert(src[i] & 0x0F, 4, 8);
					dest[outInfo.componentCount * i + 1] = PixelFormat::convert(src[i] & 0xF0, 4, 8);
					
				}
				
				NSData *outputData = [NSData dataWithBytes:dest length:pixelCount * outInfo.bytesPerPixel];
				free(dest);
				return outputData;
				
			}
			// silence static analyzer warning
			free(destBytes);
		}
		
	}
	return nil;
}
#pragma mark -

- (NSString *)description {
	return [[super description] stringByAppendingFormat:@"\n format == %@, container == %@", [[self class] localizedNameOfFormat:format], (container == TKDDSContainerDX10 ? @"TKDDSContainerDX10" : @"TKDDSContainerDX9")];
}


@end



static NSData *TKCreateRGBDataFromImage(const nv::Image &image, TKPixelFormat convertedPixelFormat) {
	const uint width = image.width();
	const uint height = image.height();
	const uint depth = image.depth();
	
	const Image::Format format = image.format();
	
	const NSUInteger pixelCount = width * height * depth;
	
	NSUInteger bytesPerPixel = 0;
	
	if (format == Image::Format_RGB) {
		NSCParameterAssert(convertedPixelFormat == TKPixelFormatRGB || convertedPixelFormat == TKPixelFormatRGBX);
		
		if (convertedPixelFormat == TKPixelFormatRGB) {
			bytesPerPixel = 3;
		} else if (convertedPixelFormat == TKPixelFormatRGBX) {
			bytesPerPixel = 4;
		}
	} else /* if (format == Image::Format_ARGB) */ {
		bytesPerPixel = 4;
	}
	
	const NSUInteger newLength = pixelCount * bytesPerPixel;
	
	unsigned char *rgbBytes = (unsigned char *)malloc(newLength);
	
	if (rgbBytes == NULL) {
		NSLog(@"%s() malloc(%llu) failed!", __FUNCTION__, (unsigned long long)newLength);
		return nil;
	}
	
	if (format == Image::Format_RGB) {
		
		if (convertedPixelFormat == TKPixelFormatRGB) {
			
			for (uint i = 0; i < pixelCount; i++) {
				const Color32 pixel = image.pixel(i);
				
				rgbBytes[i * bytesPerPixel + 0] = pixel.r;
				rgbBytes[i * bytesPerPixel + 1] = pixel.g;
				rgbBytes[i * bytesPerPixel + 2] = pixel.b;
			}
			
		} else if (convertedPixelFormat == TKPixelFormatRGBX) {
			
			for (uint i = 0; i < pixelCount; i++) {
				const Color32 pixel = image.pixel(i);
				
				rgbBytes[i * bytesPerPixel + 0] = pixel.r;
				rgbBytes[i * bytesPerPixel + 1] = pixel.g;
				rgbBytes[i * bytesPerPixel + 2] = pixel.b;
				rgbBytes[i * bytesPerPixel + 3] = 0;
			}
		}
		
	} else if (format == Image::Format_ARGB) {
		
		for (uint i = 0; i < pixelCount; i++) {
			const Color32 pixel = image.pixel(i);
			
			rgbBytes[i * bytesPerPixel + 0] = pixel.r;
			rgbBytes[i * bytesPerPixel + 1] = pixel.g;
			rgbBytes[i * bytesPerPixel + 2] = pixel.b;
			rgbBytes[i * bytesPerPixel + 3] = pixel.a;
		}
	}
	
	NSData *data = [[NSData alloc] initWithBytes:rgbBytes length:newLength];
	free(rgbBytes);
	return data;
}


