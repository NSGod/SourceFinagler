//
//  MDBrowser.h
//  Source Finagler
//
//  Created by Mark Douma on 2/5/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class MDBrowser;


@protocol MDBrowserDelegate <NSObject>
@optional

- (void)browser:(MDBrowser *)aBrowser sortDescriptorsDidChange:(NSArray *)oldDescriptors;

@end

enum {
	MDBrowserSortByName					= 0,
	MDBrowserSortBySize					= 1,
	MDBrowserSortByKind					= 2,
	MDBrowserSortByUndetermined			= NSIntegerMax
};

@interface MDBrowser : NSBrowser {
	NSArray			*sortDescriptors;
	
	NSInteger		fontAndIconSize;
	
	BOOL			shouldShowIcons;
	BOOL			shouldShowPreview;
	
	BOOL			highlighted;
	
}

@property (nonatomic, copy) NSArray *sortDescriptors;

@property (nonatomic, readonly, assign) BOOL shouldShowIcons;
@property (nonatomic, readonly, assign) BOOL shouldShowPreview;


- (NSInteger)fontAndIconSize;

- (NSArray *)itemsAtRowIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)columnIndex;

- (IBAction)reloadData;
- (IBAction)deselectAll:(id)sender;

@end


extern NSString * const MDBrowserSelectionDidChangeNotification;

extern NSString * const MDBrowserFontAndIconSizeKey;
extern NSString * const MDBrowserShouldShowIconsKey;
extern NSString * const MDBrowserShouldShowPreviewKey;

extern NSString * const MDBrowserSortByKey;

