//
//  MDQuickLookController.h
//  Source Finagler
//
//  Created by Mark Douma on 2/24/2009.
//  Copyright 2009 Mark Douma. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MDHLDocument, MDQuickLookPreviewViewController;


extern NSString * const MDQuickLookStartFrameKey;
extern NSString * const MDQuickLookEndFrameKey;


@interface MDQuickLookController : NSWindowController {
	IBOutlet MDQuickLookPreviewViewController	*previewViewController;
	
	
	IBOutlet NSView								*controlsView;
	
	
	NSArray										*items;			// CANNOT BE A weak (non-retained) reference
	MDHLDocument								*document;		// CANNOT BE A weak (non-retained) reference
	
	NSInteger									currentItemIndex;
	BOOL										isPlaying;
	
}

+ (MDQuickLookController *)sharedQuickLookController;

@property (retain) NSArray *items;
@property (retain) MDHLDocument *document;

- (IBAction)showPreviousItem:(id)sender;
- (IBAction)showNextItem:(id)sender;
- (IBAction)playPause:(id)sender;

- (void)showWindowByAnimatingFromStartFrame:(NSRect)startFrame toEndFrame:(NSRect)endFrame;


- (void)loadItemAtIndex:(NSInteger)anIndex;

@end



