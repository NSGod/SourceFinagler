//
//  TKImageInspectorController.h
//  Source Finagler
//
//  Created by Mark Douma on 10/24/2011.
//  Copyright 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TKImageDocument;
@class TKImageChannel;

@class TKImageInspectorController;






@protocol TKImageInspectorDataSource <NSObject>

@required

- (NSUInteger)numberOfImageChannelsInImageInspector:(TKImageInspectorController *)inspector;

- (TKImageChannel *)imageChannelAtIndex:(NSUInteger)anIndex;

- (void)imageInspectorController:(TKImageInspectorController *)inspectorController didEnableImageChannel:(TKImageChannel *)aChannel;
- (void)imageInspectorController:(TKImageInspectorController *)inspectorController didDisableImageChannel:(TKImageChannel *)aChannel;

@end


/*!
 * @abstract Methods to implement by any object in the responder chain to control the Preview Panel
 * @discussion QLPreviewPanel shows previews for items provided by the first object in the responder chain accepting to control it. You generally implement these methods in your window controller or delegate. You should never try to modify Preview panel state if you're not controlling the panel.
 */
@interface NSObject (TKImageInspectorController)

/*!
 * @abstract Sent to each object in the responder chain to find a controller.
 * @param panel The Preview Panel looking for a controller.
 * @result YES if the receiver accepts to control the panel. You should never call this method directly.
 */
- (BOOL)acceptsImageInspectorControl:(TKImageInspectorController *)controller;

/*!
 * @abstract Sent to the object taking control of the Preview Panel.
 * @param panel The Preview Panel the receiver will control.
 * @discussion The receiver should setup the preview panel (data source, delegate, binding, etc.) here. You should never call this method directly.
 */
- (void)beginImageInspectorControl:(TKImageInspectorController *)controller;

/*!
 * @abstract Sent to the object in control of the Preview Panel just before stopping its control.
 * @param panel The Preview Panel that the receiver will stop controlling.
 * @discussion The receiver should unsetup the preview panel (data source, delegate, binding, etc.) here. You should never call this method directly.
 */
- (void)endImageInspectorControl:(TKImageInspectorController *)controller;

@end






@interface TKImageInspectorController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate> {
	IBOutlet NSTableView								*tableView;
	
	IBOutlet id <TKImageInspectorDataSource>			dataSource;		// non-retained
	
	BOOL												appIsTerminating;
}

+ (TKImageInspectorController *)sharedController;

@property (assign) id <TKImageInspectorDataSource> dataSource;


- (void)reloadData;

@end



