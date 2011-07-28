//
//  TKImageExportPreviewOperation.h
//  Source Finagler
//
//  Created by Mark Douma on 7/17/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class TKImageExportPreview;

extern NSString * const TKImageExportPreviewOperationDidCompleteNotification;
extern NSString * const TKImageExportPreviewKey;


@interface TKImageExportPreviewOperation : NSOperation {
	TKImageExportPreview		*imageExportPreview;
	
}

- (id)initWithImageExportPreview:(TKImageExportPreview *)anImageExportPreview;


@property (retain) TKImageExportPreview *imageExportPreview;

- (BOOL)isEqual:(id)object;

@end
