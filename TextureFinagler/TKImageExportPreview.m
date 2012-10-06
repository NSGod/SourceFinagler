//
//  TKImageExportPreview.m
//  Texture Kit
//
//  Created by Mark Douma on 12/14/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreview.h"
#import "TKImageExportPreset.h"

#import <TextureKit/TKDDSImageRep.h>
#import <TextureKit/TKVTFImageRep.h>

#define TK_DEBUG 1

@implementation TKImageExportPreview

@synthesize imageRep, preset, imageType, imageFormat, imageFileSize, tag;


- (id)initWithPreset:(TKImageExportPreset *)aPreset tag:(NSInteger)aTag {
	if ((self = [super init])) {
		[self setPreset:aPreset];
		imageRep = nil;
		[self setImageFileSize:0];
		[self setTag:aTag];
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[preset release];
	[imageRep release];
	[imageType release];
	[imageFormat release];
	[super dealloc];
}


- (void)setPreset:(TKImageExportPreset *)aPreset {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[aPreset retain];
	[preset release];
	preset = aPreset;
	
	[self setImageType:[preset fileType]];
	[self setImageFormat:[preset format]];
	
	
//	if ([preset vtfFormat] != TKVTFNoFormat && [preset ddsFormat] == TKDDSNoFormat) {
//		[self setImageType:@"VTF"];
//		[self setImageFormat:NSStringFromVTFFormat([preset vtfFormat])];
//	} else if ([preset vtfFormat] == TKVTFNoFormat && [preset ddsFormat] != TKDDSNoFormat) {
//		[self setImageType:@"DDS"];
//		[self setImageFormat:NSStringFromDDSFormat([preset ddsFormat])];
//	}
	
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	[description appendFormat:@"\n"];
	[description appendFormat:@"preset == %@", preset];
	[description appendFormat:@"imageRep == %@", imageRep];
	[description appendFormat:@"imageType == %@", imageType];
	[description appendFormat:@"imageFormat == %@", imageFormat];
	[description appendFormat:@"imageFileSize == %lu", (unsigned long)imageFileSize];
	[description appendFormat:@"tag == %ld", (long)tag];
	return description;
}

@end



