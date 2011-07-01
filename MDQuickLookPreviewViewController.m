//
//  MDQuickLookPreviewViewController.m
//  ComplexBrowser
//
//  Created by Mark Douma on 6/27/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import "MDQuickLookPreviewViewController.h"
#import "MDHLDocument.h"
#import "MDFile.h"
#import "MDFolder.h"
#import "MDFileAdditions.h"
#import "MDFolderAdditions.h"
#import "MDTransparentView.h"
#import <WebKit/WebKit.h>

//#define MD_DEBUG 1
#define MD_DEBUG 0


@implementation MDQuickLookPreviewViewController


//- (void)dealloc {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[super dealloc];
//}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[super awakeFromNib];
	
	isQuickLookPanel = YES;
}



- (void)setRepresentedObject:(id)representedObject {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
//	// force our nib to load if it isn't already
//	[self view];

	// representedObject can be:
	//		nil
	//		an MDHLDocument
	//		an MDFile or MDFolder
	
	if (isPlayingSound) {
		[sound stop];
		[self setSound:nil];
	}
	if (representedObject) {
		if ([representedObject isKindOfClass:[MDHLDocument class]]) {
			[box setContentView:imageViewView];
			
		} else if ([representedObject isKindOfClass:[MDItem class]]) {
			if ([representedObject respondsToSelector:@selector(fileType)]) {
				MDFileType fileType = MDFileTypeNone;
				fileType = [(MDFile *)representedObject fileType];
				switch (fileType) {
					case MDFileTypeHTML :
						[[webView mainFrame] loadHTMLString:[(MDFile *)representedObject stringValue] baseURL:nil];
						[box setContentView:webViewView];
						break;
						
					case MDFileTypeText :
						[textView setString:[(MDFile *)representedObject stringValue]];
						[box setContentView:textViewView];
						break;
						
					case MDFileTypeImage :
						[box setContentView:imageViewView];
						break;
						
					case MDFileTypeSound :
						[box setContentView:soundViewView];
						[self setSound:[(MDFile *)representedObject sound]];
						[sound setDelegate:self];
						break;
						
					case MDFileTypeMovie :
						[box setContentView:movieViewView];
						break;
						
					case MDFileTypeOther :
						[box setContentView:imageViewView];
						break;
						
					default:
						break;
				}
			}
		}
	} else {
		[box setContentView:imageViewView];
	}
	[super setRepresentedObject:representedObject];
	
}


//- (void)cleanup {
//#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//}

@end

