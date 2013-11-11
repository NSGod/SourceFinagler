//
//  TKVTFTexture.mm
//  Texture Kit
//
//  Created by Mark Douma on 11/16/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKVTFTexture.h>
#import <TextureKit/TKVTFImageRep.h>

#if TK_ENABLE_OPENGL3
	#import <OpenGL/gl3ext.h>
#else
	#import <OpenGL/glext.h>
#endif

#import <VTF/VTF.h>



#define TK_DEBUG 1



using namespace VTFLib;

struct TKVTFTextureFormatMapping {
	VTFImageFormat		vtfFormat;
	VTFImageFormat		vtfNativeFormat;
	BOOL				isCompressed;
	GLenum				pixelFormat;
	GLenum				dataType;
};

static const TKVTFTextureFormatMapping TKVTFTextureFormatMappingTable[] = {
	{ IMAGE_FORMAT_RGBA8888,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
#if TK_ENABLE_OPENGL3
	{ IMAGE_FORMAT_ABGR8888,			IMAGE_FORMAT_BGRA8888,		NO,		GL_BGRA,					GL_UNSIGNED_BYTE},
#else
	{ IMAGE_FORMAT_ABGR8888,			IMAGE_FORMAT_NONE,			NO,		GL_ABGR_EXT,				GL_UNSIGNED_BYTE},
#endif
	{ IMAGE_FORMAT_RGB888,				IMAGE_FORMAT_NONE,			NO,		GL_RGB,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_BGR888,				IMAGE_FORMAT_NONE,			NO,		GL_BGR,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_RGB565,				IMAGE_FORMAT_NONE,			NO,		GL_RGB,						GL_UNSIGNED_SHORT_5_6_5},
	{ IMAGE_FORMAT_I8,					IMAGE_FORMAT_NONE,			NO,		GL_RED,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_IA88,				IMAGE_FORMAT_NONE,			NO,		GL_RG,						GL_UNSIGNED_BYTE},
//	{ IMAGE_FORMAT_P8,					GL_COLOR_INDEX,							GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_A8,					IMAGE_FORMAT_NONE,			NO,		GL_ALPHA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_RGB888_BLUESCREEN,	IMAGE_FORMAT_NONE,			NO,		GL_RGB,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_BGR888_BLUESCREEN,	IMAGE_FORMAT_NONE,			NO,		GL_BGR,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_ARGB8888,			IMAGE_FORMAT_RGBA8888,		NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_BGRA8888,			IMAGE_FORMAT_NONE,			NO,		GL_BGRA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_DXT1,				IMAGE_FORMAT_NONE,			YES,	GL_COMPRESSED_RGB_S3TC_DXT1_EXT,		0},
	{ IMAGE_FORMAT_DXT3,				IMAGE_FORMAT_NONE,			YES,	GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,		0},
	{ IMAGE_FORMAT_DXT5,				IMAGE_FORMAT_NONE,			YES,	GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,		0},
	{ IMAGE_FORMAT_BGRX8888,			IMAGE_FORMAT_NONE,			NO,		GL_BGRA,								GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_BGR565,				IMAGE_FORMAT_NONE,			NO,		GL_BGR,						GL_UNSIGNED_SHORT_5_6_5},
	{ IMAGE_FORMAT_BGRX5551,			IMAGE_FORMAT_NONE,			NO,		GL_BGRA,					GL_UNSIGNED_SHORT_5_5_5_1},
	{ IMAGE_FORMAT_BGRA4444,			IMAGE_FORMAT_NONE,			NO,		GL_BGRA,					GL_UNSIGNED_SHORT_4_4_4_4},
	{ IMAGE_FORMAT_DXT1_ONEBITALPHA,	IMAGE_FORMAT_NONE,			YES,	GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,		0},
	{ IMAGE_FORMAT_BGRA5551,			IMAGE_FORMAT_NONE,			NO,		GL_BGRA,								GL_UNSIGNED_SHORT_5_5_5_1},
	{ IMAGE_FORMAT_UV88,				IMAGE_FORMAT_NONE,			NO,		GL_RG,						GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_UVWQ8888,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_RGBA16161616F,		IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_HALF_FLOAT},
	{ IMAGE_FORMAT_RGBA16161616,		IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_SHORT},
	{ IMAGE_FORMAT_UVLX8888,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_R32F,				IMAGE_FORMAT_NONE,			NO,		GL_RED,						GL_FLOAT},
	{ IMAGE_FORMAT_RGB323232F,			IMAGE_FORMAT_NONE,			NO,		GL_RGB,						GL_FLOAT},
	{ IMAGE_FORMAT_RGBA32323232F,		IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_FLOAT},
	{ IMAGE_FORMAT_NV_DST16,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_NV_DST24,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_NV_INTZ,				IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_NV_RAWZ,				IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_ATI_DST16,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_ATI_DST24,			IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_NV_NULL,				IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_ATI2N,				IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE},
	{ IMAGE_FORMAT_ATI1N,				IMAGE_FORMAT_NONE,			NO,		GL_RGBA,					GL_UNSIGNED_BYTE}

};
static const NSUInteger TKVTFTextureFormatMappingTableCount = sizeof(TKVTFTextureFormatMappingTable)/sizeof(TKVTFTextureFormatMappingTable[0]);

static inline TKVTFTextureFormatMapping TKVTFFormatMappingForImageFormat(VTFImageFormat vtfFormat) {
	for (NSUInteger i = 0; i < TKVTFTextureFormatMappingTableCount; i++) {
		if (TKVTFTextureFormatMappingTable[i].vtfFormat == vtfFormat) {
			TKVTFTextureFormatMapping formatMapping = TKVTFTextureFormatMappingTable[i];
			return formatMapping;
		}
	}
	TKVTFTextureFormatMapping formatMapping = {IMAGE_FORMAT_NONE, IMAGE_FORMAT_NONE, 0, 0};
	return formatMapping;
}

struct TKOpenGLCubeMapMapping {
	VTFCubeMapFace		vtfCubeMapFace;
	GLenum				cubeMapFace;
};

static const TKOpenGLCubeMapMapping TKOpenGLCubeMapMappingTable[] = {
	{CUBEMAP_FACE_RIGHT,  GL_TEXTURE_CUBE_MAP_POSITIVE_X},		// +x
	{CUBEMAP_FACE_LEFT,  GL_TEXTURE_CUBE_MAP_NEGATIVE_X},		// -x
	{CUBEMAP_FACE_BACK,  GL_TEXTURE_CUBE_MAP_POSITIVE_Y},		// +y
	{CUBEMAP_FACE_FRONT,  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y},		// -y
	{CUBEMAP_FACE_UP,  GL_TEXTURE_CUBE_MAP_POSITIVE_Z},			// +z
	{CUBEMAP_FACE_DOWN,  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z}		// -z
};
static const NSUInteger TKOpenGLCubeMapMappingTableCount = sizeof(TKOpenGLCubeMapMappingTable)/sizeof(TKOpenGLCubeMapMappingTable[0]);

static inline GLenum TKOpenGLCubeMapFaceFromVTFCubeMapFace(VTFCubeMapFace vtfCubeMapFace) {
	for (NSUInteger i = 0; i < TKOpenGLCubeMapMappingTableCount; i++) {
		if (TKOpenGLCubeMapMappingTable[i].vtfCubeMapFace == vtfCubeMapFace) {
			return TKOpenGLCubeMapMappingTable[i].cubeMapFace;
		}
	}
	return 0;
}


@implementation TKVTFTexture


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		OSType magic = 0;
		[aData getBytes:&magic length:sizeof(magic)];
		magic = NSSwapBigIntToHost(magic);
		
		CVTFFile *file = new CVTFFile();
		if (file == 0) {
			NSLog(@"[%@ %@] CVTFFile() returned 0!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
		if (file->Load([aData bytes], [aData length], vlFalse) == NO) {
			if (magic == TKVTFMagic) {
				NSLog(@"[%@ %@] file->Load() failed! (DOES appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
			} else {
				NSLog(@"[%@ %@] file->Load() failed! (does not appear to be a valid VTF; magic == 0x%x, %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned int)magic, NSFileTypeForHFSTypeCode(magic));
			}
			delete file;
			return nil;
		}
		
//		vlUInt frameCount = file->GetFrameCount();
		vlUInt faceCount = file->GetFaceCount();
		vlUInt mipmapCount = file->GetMipmapCount();
		vlUInt sliceCount = file->GetDepth();
		
		VTFImageFormat imageFormat = file->GetFormat();
		
		width = file->GetWidth();
		height = file->GetHeight();
		
		TKVTFTextureFormatMapping formatMapping = TKVTFFormatMappingForImageFormat(imageFormat);
		
		pixelFormat = formatMapping.pixelFormat;
		dataType = formatMapping.dataType;
		
		glGenTextures(1, &name);
		glBindTexture(GL_TEXTURE_2D, name);
		
		// Set up filter and wrap modes for this texture object
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		
		// Indicate that pixel rows are tightly packed
		//  (defaults to stride of 4 which is kind of only good for
		//  RGBA or FLOAT data types)
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		
		for (vlUInt mipmapIndex = 0; mipmapIndex < mipmapCount; mipmapIndex++) {
			for (vlUInt faceIndex = 0; faceIndex < faceCount; faceIndex++) {
				
				vlUInt mipmapWidth = 0;
				vlUInt mipmapHeight = 0;
				vlUInt mipmapDepth = 0;
				
				CVTFFile::ComputeMipmapDimensions(width, height, file->GetDepth(), mipmapIndex, mipmapWidth, mipmapHeight, mipmapDepth);
				
				vlUInt existingBytesLength = CVTFFile::ComputeMipmapSize(width, height, sliceCount, mipmapIndex, imageFormat);
				vlByte *existingBytes = file->GetData(0, faceIndex, 0, mipmapIndex);
				
				vlByte *convertedBytes = 0;
				vlInt convertedBytesLength = 0;
				
				if (formatMapping.vtfNativeFormat != IMAGE_FORMAT_NONE) {
					convertedBytesLength = CVTFFile::ComputeMipmapSize(width, height, sliceCount, mipmapIndex, formatMapping.vtfNativeFormat);
					convertedBytes = new vlByte[convertedBytesLength];
					
					if (convertedBytes == 0) {
						NSLog(@"[%@ %@] new [%lu] failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)convertedBytesLength);
						continue;
					}
					
					if (!CVTFFile::Convert(existingBytes, convertedBytes, mipmapWidth, mipmapHeight, imageFormat, formatMapping.vtfNativeFormat)) {
						NSLog(@"[%@ %@] CVTFFile::Convert() failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
						delete [] convertedBytes;
						continue;
					}
				}
				
				
				if (faceCount > 1) {
					if (formatMapping.isCompressed) {
						
						glCompressedTexImage2D(TKOpenGLCubeMapFaceFromVTFCubeMapFace(static_cast<VTFCubeMapFace>(faceIndex)),
											   mipmapIndex, pixelFormat, mipmapWidth, mipmapHeight, 0, existingBytesLength, existingBytes);
						
					} else {
						glTexImage2D(TKOpenGLCubeMapFaceFromVTFCubeMapFace(static_cast<VTFCubeMapFace>(faceIndex)),
									 mipmapIndex, pixelFormat, mipmapWidth, mipmapHeight, 0, pixelFormat, dataType, (convertedBytes ? convertedBytes : existingBytes));
					}
					
				} else {
					if (formatMapping.isCompressed) {
						glCompressedTexImage2D(GL_TEXTURE_2D, mipmapIndex, pixelFormat, mipmapWidth, mipmapHeight, 0, existingBytesLength, existingBytes);
						
					} else {
						glTexImage2D(GL_TEXTURE_2D, mipmapIndex, pixelFormat, mipmapWidth, mipmapHeight, 0, pixelFormat, dataType, (convertedBytes ? convertedBytes : existingBytes));
						
					}
				}
			}
		}
		
		TKGetGLError();
		
		delete file;
		
	}
	return self;
}




@end





