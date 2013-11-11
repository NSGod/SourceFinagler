//
//  TKImageExportPreview.m
//  Texture Kit
//
//  Created by Mark Douma on 12/14/2010.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreview.h"
#import "TKImageExportPreset.h"
#import "TKImageExportController.h"
#import <TextureKit/TextureKit.h>


#define TK_DEBUG 1

@implementation TKImageExportPreview

@synthesize image, tag, controller, imageFileSize, imageRep, preset;


- (id)initWithController:(TKImageExportController *)aController image:(TKImage *)anImage preset:(TKImageExportPreset *)aPreset tag:(NSInteger)aTag {
	if (anImage == nil || aPreset == nil) return nil;
	if ((self = [super init])) {
		controller = aController;
		image = [anImage retain];
		preset = [aPreset retain];
		tag = aTag;
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	controller = nil;
	[image release];
	[imageRep release];
	[preset release];
	[super dealloc];
}


- (void)setNilValueForKey:(NSString *)key {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([key isEqualToString:@"imageFileSize"]) {
		imageFileSize = 0;
	} else if ([key isEqualToString:@"tag"]) {
		tag = 0;
	} else {
		return [super setNilValueForKey:key];
	}
}


- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[self class]]) {
		if ([(TKImageExportPreview *)object controller] == controller &&
			[(TKImageExportPreview *)object tag] == tag) {
			return YES;
		}
	}
	return NO;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	[description appendFormat:@", "];
	[description appendFormat:@"preset == %@, ", preset];
//	[description appendFormat:@"imageRep == %@, ", imageRep];
//	[description appendFormat:@"imageFileSize == %lu, ", imageFileSize];
	[description appendFormat:@"tag == %ld", (long)tag];
	return description;
}

@end



