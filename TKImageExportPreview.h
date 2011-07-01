//
//  TKImageExportPreview.h
//  Texture Kit
//
//  Created by Mark Douma on 12/14/2010.
//  Copyright (c) 2010-2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKImageRep, TKImageExportPreset;

@interface TKImageExportPreview : NSObject {
	TKImageExportPreset		*preset;
	
	TKImageRep				*imageRep;
	
	NSString				*imageType;
	NSString				*imageFormat;
	NSUInteger				imageFileSize;
	
	NSInteger				tag;		// 0 thru 3
}

- (id)initWithPreset:(TKImageExportPreset *)aPreset tag:(NSInteger)aTag;


@property (retain) TKImageRep *imageRep;
@property (nonatomic, retain) TKImageExportPreset *preset;

@property (retain) NSString *imageType;
@property (retain) NSString *imageFormat;
@property (assign) NSUInteger imageFileSize;

@property (assign) NSInteger tag;

@end
