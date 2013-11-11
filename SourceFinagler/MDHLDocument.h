//
//  MDHLDocument.h
//  Source Finagler
//
//  Created by Mark Douma on 1/30/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import <Cocoa/Cocoa.h>


@class MDOutlineView, MDBrowser, MDMetalBevelView, MDStatusImageView, MDInspectorController, MDBottomBar,
MDPreviewViewController, MDPathControlView, MDInspectorView;

@class HKItem, HKFile, HKArchiveFile;


extern int CoreDockSetTrashFull(int full) __attribute__((weak_import));


enum {
	MDListViewMode		= 1,
	MDColumnViewMode	= 2,
};


extern NSString * const MDHLDocumentErrorDomain;
extern NSString * const MDHLDocumentURLKey;


@interface MDHLDocument : NSDocument <NSToolbarDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSBrowserDelegate> {

	IBOutlet NSWindow								*hlWindow;
	
	IBOutlet NSBox									*mainBox;
	
	IBOutlet MDInspectorView						*searchInspectorView;
	IBOutlet NSPredicateEditor						*searchPredicateEditor;
	
	IBOutlet NSToolbarItem							*searchToolbarItem;
	IBOutlet NSSearchField							*searchField;
	
	IBOutlet MDStatusImageView						*statusImageView1;
	IBOutlet MDStatusImageView						*statusImageView2;
	
	IBOutlet MDBottomBar							*bottomBar;
	
	IBOutlet MDMetalBevelView						*outlineViewView;
	IBOutlet MDOutlineView							*outlineView;
	IBOutlet NSTableColumn							*nameColumn;
	IBOutlet NSScrollView							*scrollView;
	
	IBOutlet MDMetalBevelView						*browserView;
	IBOutlet MDBrowser								*browser;
	
	MDPreviewViewController							*browserPreviewViewController;
	
	
	IBOutlet NSMenu									*outlineViewMenu;
	IBOutlet NSMenuItem								*outlineViewMenuHelpMenuItem;
	IBOutlet NSMenuItem								*outlineViewMenuShowInspectorMenuItem;
	NSMenuItem										*outlineViewMenuShowQuickLookMenuItem;	// not in nib
	IBOutlet NSMenuItem								*outlineViewMenuShowViewOptionsMenuItem;
	
	
	IBOutlet NSPopUpButton							*actionButton;
	IBOutlet NSMenuItem								*actionButtonActionImageItem;			// in nib but not referenced
	IBOutlet NSMenuItem								*actionButtonShowInspectorMenuItem;
	NSMenuItem										*actionButtonShowQuickLookMenuItem;		// not in nib
	IBOutlet NSMenuItem								*actionButtonShowViewOptionsMenuItem;
	
	
	IBOutlet NSMenu									*browserMenu;
	IBOutlet NSMenuItem								*browserMenuShowInspectorMenuItem;
	NSMenuItem										*browserMenuShowQuickLookMenuItem;		// not in nib
	IBOutlet NSMenuItem								*browserMenuShowViewOptionsMenuItem;
	
	
	IBOutlet NSSegmentedControl						*viewSwitcherControl;
	
	IBOutlet MDInspectorView						*pathControlInspectorView;
	IBOutlet MDPathControlView						*pathControlView;
	IBOutlet NSPathControl							*pathControl;
	IBOutlet NSMenu									*pathControlMenu;
	
	IBOutlet NSProgressIndicator					*progressIndicator;
	
	NSToolTipTag									statusImageViewTag1;
	NSToolTipTag									statusImageViewTag2;
	
	HKArchiveFile									*file;
	
	NSMutableDictionary								*copyOperationsAndTags;
	
	NSInteger					viewMode;
		
	NSMutableArray				*searchResults;
	NSPredicate					*searchPredicate;
    NSUInteger					searchPredicateEditorRowCount;
	
		
	
	NSUInteger					outlineViewItemCount;
	
	NSImage						*image;
	
	
	NSString					*version;
	
	NSString					*kind;
	
	
	BOOL						shouldShowInvisibleItems;
	BOOL						isSearching;
	BOOL						outlineViewIsReloadingData;
	
}

@property (assign) BOOL shouldShowInvisibleItems;


- (HKArchiveFile *)file;


@property (retain) NSImage *image;
@property (assign) BOOL outlineViewIsReloadingData;

@property (retain) NSString *version;
@property (assign, setter=setSearching:) BOOL isSearching;
@property (retain) NSString *kind;

@property (retain) NSPredicate *searchPredicate;


- (IBAction)find:(id)sender;
- (IBAction)findAdvanced:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)searchPredicateEditorChanged:(id)sender;

// path control methods
- (IBAction)revealInFinder:(id)sender;
- (IBAction)revealParentInFinder:(id)sender;


- (IBAction)switchViewMode:(id)sender;

- (IBAction)browserSelect:(id)sender;

// we define this method and intercept it so that our validateMenuItem: can properly update the menu item as long as a font document is open.
- (IBAction)toggleShowQuickLook:(id)sender;
- (IBAction)toggleShowPathBar:(id)sender;

- (NSDate *)fileCreationDate;
- (NSNumber *)fileSize;


@end



	
/************** 1.5 - for document  ************/


extern NSString * const MDDocumentWindowSavedFrameKey;

extern NSString * const MDShouldShowInvisibleItemsKey;

extern NSString * const MDDocumentViewModeDidChangeNotification;
extern NSString * const MDDocumentViewModeKey;

extern NSString * const MDDocumentNameKey;
extern NSString * const MDDidSwitchDocumentNotification;

extern NSString * const MDShouldShowInspectorKey;
extern NSString * const MDShouldShowInspectorDidChangeNotification;

extern NSString * const MDShouldShowQuickLookKey;
extern NSString * const MDShouldShowQuickLookDidChangeNotification;

extern NSString * const MDShouldShowPathBarKey;
extern NSString * const MDShouldShowPathBarDidChangeNotification;


extern NSString * const MDSelectedItemsDidChangeNotification;
extern NSString * const MDSelectedItemsKey;
extern NSString * const MDSelectedItemsDocumentKey;


extern NSString * const MDSystemSoundEffectsLeopardBundleIdentifierKey;
extern NSString * const MDSystemSoundEffectsLeopardKey; // NSNumber (int)


extern NSString * const MDShowBrowserPreviewInspectorPaneKey;

extern NSString * const MDDraggedItemsPboardType;
extern NSString * const MDCopiedItemsPboardType;


extern NSString * const MDViewKey;

extern NSString * const MDWillSwitchViewNotification;

extern NSString * const MDViewNameKey;

	
