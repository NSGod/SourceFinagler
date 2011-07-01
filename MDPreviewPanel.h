//
//  MDPreviewPanel.h
//  Source Finagler
//
//  Created by Mark Douma on 10/11/2010.
//  Copyright 2010 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol MDPreviewPanelDelegate;
@protocol MDPreviewPanelDataSource;
@protocol MDPreviewItem;


@interface MDPreviewPanel : NSPanel {
	
	id <MDPreviewPanelDelegate>		delegate;
	id <MDPreviewPanelDataSource>	dataSource;
	
	id								currentController;
	NSInteger						currentPreviewItemIndex;
	id <MDPreviewItem>				currentPreviewItem;
	
	
	
}

+ (MDPreviewPanel *)sharedPreviewPanel;
+ (BOOL)sharedPreviewPanelExists;


- (void)updateController;

@property (assign) id <MDPreviewPanelDataSource> dataSource;
@property (assign) id <MDPreviewPanelDelegate>	 delegate;
@property (readonly) id currentController;

// The index of the currently previewed item in the preview panel or NSNotFound if there is none.
@property NSInteger currentPreviewItemIndex;


- (void)reloadData;

- (void)refreshCurrentPreviewItem;


/*!
 * @abstract The currently previewed item in the preview panel or nil if there is none.
 */
@property(readonly) id <QLPreviewItem> currentPreviewItem;

/*!
 * @abstract The current panel's display state.
 */
@property(retain) id displayState;

/*
 * Managing Full screen mode
 */

/*!
 * @abstract Enters full screen mode.
 * @discussion If panel is not on-screen, the panel will go directly to full screen mode.
 */
- (BOOL)enterFullScreenMode:(NSScreen *)screen withOptions:(NSDictionary *)options;

/*!
 * @abstract Exits full screen mode.
 */
- (void)exitFullScreenModeWithOptions:(NSDictionary *)options;

/*!
 * @abstract YES if the panel is currently open and in full screen mode.
 */
@property(readonly, getter=isInFullScreenMode) BOOL inFullScreenMode;


@end



@protocol MDPreviewPanelDataSource <NSObject>

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(MDPreviewPanel *)panel;


- (id <MDPreviewItem>)previewPanel:(MDPreviewPanel *)panel previewItemAtIndex:(NSInteger)index;

@end



@protocol MDPreviewPanelDelegate <NSWindowDelegate>


/* Invoked by the preview panel when it receives an event it doesn't handle.
 * Returns NO if the receiver did not handle the event.						*/
- (BOOL)previewPanel:(MDPreviewPanel *)panel handleEvent:(NSEvent *)event;


/* Invoked when the preview panel opens or closes to provide a zoom effect.
 * Return NSZeroRect if there is no origin point, this will produce a fade of the panel. The coordinates are screen based.  */

- (NSRect)previewPanel:(MDPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <MDPreviewItem>)item;


/* Invoked when the preview panel opens or closes to provide a smooth transition when zooming.
   contentRect The rect within the image that actually represents the content of the document. For example, for icons the actual rect is generally smaller than the icon itself.
 * @discussion Return an image the panel will crossfade with when opening or closing. You can specify the actual "document" content rect in the image in contentRect.					*/

- (id)previewPanel:(MDPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect;

@end
