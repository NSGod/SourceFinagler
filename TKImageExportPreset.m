//
//  TKImageExportPreset.m
//  Texture Kit
//
//  Created by Mark Douma on 12/11/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import "TKImageExportPreset.h"

NSString * const TKImageExportNameKey						= @"TKImageExportName";
NSString * const TKImageExportFileTypeKey					= @"TKImageExportFileType";
NSString * const TKImageExportFormatKey						= @"TKImageExportFormat";
NSString * const TKImageExportDXTCompressionQualityKey		= @"TKImageExportDXTCompressionQuality";
NSString * const TKImageExportMipmapsKey					= @"TKImageExportMipmaps";



@implementation TKImageExportPreset

@synthesize name, fileType, format, compressionQuality, mipmaps;


+ (NSArray *)imageExportPresetsWithContentsOfArrayAtPath:(NSString *)aPath {
	if (aPath == nil) return nil;
	NSMutableArray *imageExportPresets = [NSMutableArray array];
	NSArray *array = [NSArray arrayWithContentsOfFile:aPath];
	if (array) {
		for (NSDictionary *dictionary in array) {
			TKImageExportPreset *preset = [TKImageExportPreset imageExportPresetWithDictionary:dictionary];
			if (preset) [imageExportPresets addObject:preset];
		}
	}
	NSArray *rImageExportPresets = [imageExportPresets copy];
	return [rImageExportPresets autorelease];
}


+ (NSArray *)dictionaryRepresentationsOfImageExportPresets:(NSArray *)presets {
	if (presets == nil) return nil;
	NSMutableArray *dictReps = [NSMutableArray array];
	for (TKImageExportPreset *preset in presets) {
		NSDictionary *dictRep = [preset dictionaryRepresentation];
		if (dictRep) [dictReps addObject:dictRep];
	}
	NSArray *rDictReps = [dictReps copy];
	return [rDictReps autorelease];
}


+ (id)imageExportPresetWithDictionary:(NSDictionary *)aDictionary {
	return [[[[self class] alloc] initWithDictionary:aDictionary] autorelease];
}

+ (id)imageExportPresetWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps {
	return [[[[self class] alloc] initWithName:aName fileType:aFileType format:aFormat compressionQuality:aQuality mipmaps:aMipmaps] autorelease];
}


- (id)initWithName:(NSString *)aName fileType:(NSString *)aFileType format:(NSString *)aFormat compressionQuality:(NSString *)aQuality mipmaps:(BOOL)aMipmaps {
	if ((self = [super init])) {
		[self setName:aName];
		[self setFileType:aFileType];
		[self setFormat:aFormat];
		[self setCompressionQuality:aQuality];
		[self setMipmaps:aMipmaps];
	}
	return self;
}


- (id)initWithDictionary:(NSDictionary *)aDictionary {
	if ((self = [super init])) {
		[self setName:[aDictionary objectForKey:TKImageExportNameKey]];
		[self setFileType:[aDictionary objectForKey:TKImageExportFileTypeKey]];
		[self setFormat:[aDictionary objectForKey:TKImageExportFormatKey]];
		[self setCompressionQuality:[aDictionary objectForKey:TKImageExportDXTCompressionQualityKey]];
		[self setMipmaps:[[aDictionary objectForKey:TKImageExportMipmapsKey] boolValue]];
		
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	if ((self = [super init])) {
		[self setName:[coder decodeObjectForKey:TKImageExportNameKey]];
		[self setFileType:[coder decodeObjectForKey:TKImageExportFileTypeKey]];
		[self setFormat:[coder decodeObjectForKey:TKImageExportFormatKey]];
		[self setCompressionQuality:[coder decodeObjectForKey:TKImageExportDXTCompressionQualityKey]];
		[self setMipmaps:[[coder decodeObjectForKey:TKImageExportMipmapsKey] boolValue]];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:name forKey:TKImageExportNameKey];
	[coder encodeObject:fileType forKey:TKImageExportFileTypeKey];
	[coder encodeObject:format forKey:TKImageExportFormatKey];
	[coder encodeObject:compressionQuality forKey:TKImageExportDXTCompressionQualityKey];
	[coder encodeObject:[NSNumber numberWithBool:mipmaps] forKey:TKImageExportMipmapsKey];
}

- (id)copyWithZone:(NSZone *)zone {
	TKImageExportPreset *copy = [[TKImageExportPreset alloc] initWithName:name
																 fileType:fileType
																   format:format
													   compressionQuality:compressionQuality
																  mipmaps:mipmaps];
	
	return copy;
}

- (void)dealloc {
	[name release];
	[fileType release];
	[format release];
	[compressionQuality release];
	[super dealloc];
}

- (NSDictionary *)dictionaryRepresentation {
	NSDictionary *dictionaryRepresentation = [NSDictionary dictionaryWithObjectsAndKeys:name,TKImageExportNameKey,
											  fileType,TKImageExportFileTypeKey,
											  format,TKImageExportFormatKey,
											  compressionQuality,TKImageExportDXTCompressionQualityKey,
											  [NSNumber numberWithBool:mipmaps],TKImageExportMipmapsKey, nil];
	return dictionaryRepresentation;
}


//- (BOOL)isEqual:(id)object {
//	if ([object isKindOfClass:[self class]]) {
//		if ([[object name] isEqualToString:name] &&
//			[object vtfFormat
//		return [object
//	}
//	return NO;
//}



- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithString:[super description]];
	[description appendFormat:@"%@, ", name];
	[description appendFormat:@"%@, ", fileType];
	[description appendFormat:@"%@, ", format];
	[description appendFormat:@"%@, ", compressionQuality];
	[description appendFormat:@"mipmaps == %@", (mipmaps ? @"YES" : @"NO")];
	return description;
}

@end


