//
//  MDPreviewViewController.m
//  Source Finagler
//
//  Created by Mark Douma on 9/30/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import "MDPreviewViewController.h"
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>
#import "MDTransparentView.h"
#import "MDHLDocument.h"
#import "MDFileAdditions.h"
#import "MDFolderAdditions.h"


//#define MD_DEBUG 1
#define MD_DEBUG 0


@implementation MDPreviewViewController

@synthesize sound, isPlayingSound, isQuickLookPanel;


- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self initWithNibName:@"MDHLColumnPreviewView" bundle:nil];
}


- (void)awakeFromNib {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	isQuickLookPanel = NO;
	[textView setFont:[NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]]];
}



- (void)setRepresentedObject:(id)representedObject {
#if MD_DEBUG
	NSLog(@"[%@ %@] representedObject == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), representedObject);
#endif
	
	if (isPlayingSound) {
		[sound stop];
		[self setSound:nil];
	}
	
	// representedObject can be:
	//		nil
	//		an MDHLDocument
	//		an MDFile or MDFolder
	if (!isQuickLookPanel) {
		if (representedObject) {
			if ([representedObject isKindOfClass:[MDHLDocument class]]) {
				[box setContentView:imageViewView];
				
			} else if ([representedObject isKindOfClass:[MDItem class]]) {
				if ([representedObject respondsToSelector:@selector(fileType)]) {
					MDFileType fileType = MDFileTypeNone;
					fileType = [(MDFile *)representedObject fileType];
					switch (fileType) {
						case MDFileTypeHTML :
						case MDFileTypeText :
						case MDFileTypeOther :
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
							
						default:
							break;
					}
				}
			}
		} else {
			[box setContentView:imageViewView];
		}
	}
	[super setRepresentedObject:representedObject];
}



- (void)sound:(NSSound *)aSound didFinishPlaying:(BOOL)didFinishPlaying {
	if (didFinishPlaying) {
		[soundButton setImage:[NSImage imageNamed:@"play"]];
	}
}



- (IBAction)togglePlaySound:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([sound isPlaying]) {
		[soundButton setImage:[NSImage imageNamed:@"play"]];
		[sound stop];
	} else {
		[soundButton setImage:[NSImage imageNamed:@"pause"]];
		[sound play];
	}
}


@end
