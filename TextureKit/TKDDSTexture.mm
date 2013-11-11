//
//  TKDDSTexture.mm
//  Texture Kit
//
//  Created by Mark Douma on 11/16/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKDDSTexture.h>
#import <TextureKit/TKDDSImageRep.h>

#if TK_ENABLE_OPENGL3
	#import <OpenGL/gl3ext.h>
#else
	#import <OpenGL/glext.h>
#endif

#import <NVTextureTools/NVTextureTools.h>



#define TK_DEBUG 1


using namespace nv;
using namespace nvtt;


struct TKDDSTextureFormatMapping {
	D3DFORMAT			d3dFormat;
	DXGI_FORMAT			dxgiFormat;
	GLenum				pixelFormat;
	GLenum				dataType;
};

static const TKDDSTextureFormatMapping TKDDSTextureFormatMappingTable[] = {
	{}
	
};





@implementation TKDDSTexture


- (id)initWithData:(NSData *)aData {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		OSType magic = 0;
		[aData getBytes:&magic length:sizeof(magic)];
		magic = NSSwapBigIntToHost(magic);
		
		DirectDrawSurface *dds = new DirectDrawSurface((unsigned char *)[aData bytes], [aData length]);
		
		if (dds == 0) {
			NSLog(@"[%@ %@] new DirectDrawSurface() with data failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			return nil;
		}
		
#if TK_DEBUG
		NSLog(@"[%@ %@] dds info == \n", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		dds->printInfo();
#endif
		
		if (!dds->isValid() || !dds->isSupported() || (dds->width() > 65535) || (dds->height() > 65535)) {
			if (!dds->isValid()) {
				NSLog(@"[%@ %@] dds image is not valid, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			} else if (!dds->isSupported()) {
				NSLog(@"[%@ %@] dds image format is not supported, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			} else {
				NSLog(@"[%@ %@] dds image dimensions are too large, info follows:", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			}
			dds->printInfo();
			delete dds;
			return nil;
		}
		
		width = dds->width();
		height = dds->height();
		
		uint surfaceSize = dds->surfaceSize(0);
		
		data = (GLubyte *)malloc(surfaceSize);
		
		if (data == NULL) {
			NSLog(@"[%@ %@] malloc(surfaceSize) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			
		}
		
		if (!dds->readSurface(0, 0, data, surfaceSize)) {
			NSLog(@"[%@ %@] dds->readSurface(0, 0, data, surfaceSize) failed!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
			
		}
		
		delete dds;
	}
	return self;
}









@end






