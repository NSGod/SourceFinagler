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


typedef enum MDHLDocumentViewMode {
	MDHLDocumentNoViewMode			= 0,
	MDHLDocumentListViewMode		= 1,
	MDHLDocumentColumnViewMode		= 2,
} MDHLDocumentViewMode;


extern NSString * const MDHLDocumentErrorDomain;
extern NSString * const MDHLDocumentURLKey;


@interface MDHLDocument : NSDocument <NSToolbarDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSBrowserDelegate, NSMenuDelegate> {

	IBOutlet NSWindow								*hlWindow;
	
	IBOutlet NSBox									*mainBox;
	
	IBOutlet MDInspectorView						*searchInspectorView;
	IBOutlet NSPredicateEditor						*searchPredicateEditor;
	
	IBOutlet NSToolbarItem							*searchToolbarItem;
	IBOutlet NSSearchField							*searchField;
	
	IBOutlet MDStatusImageView						*statusImageView1;
	IBOutlet MDStatusImageView						*statusImageView2;
	IBOutlet MDStatusImageView						*statusImageView3;
	
	IBOutlet MDBottomBar							*bottomBar;
	
	IBOutlet NSButton								*installSourceAddonButton;
	
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
	
	MDHLDocumentViewMode							viewMode;
		
	NSMutableArray									*searchResults;
	NSPredicate										*searchPredicate;
    NSUInteger										searchPredicateEditorRowCount;
	
		
	NSUInteger										outlineViewItemCount;
	
	NSImage											*image;
	NSString										*version;
	NSString										*kind;
	
	
	BOOL											shouldShowInvisibleItems;
	BOOL											isSearching;
	BOOL											outlineViewIsReloadingData;
	BOOL											outlineViewIsSettingUpInitialColumns;
	
}

@property (readonly, nonatomic, retain) HKArchiveFile *file;


@property (readonly, nonatomic, retain) NSImage *image;
@property (readonly, nonatomic, retain) NSString *version;
@property (readonly, nonatomic, retain) NSString *kind;

@property (readonly, nonatomic, assign) MDHLDocumentViewMode viewMode;

@property (readonly, nonatomic, retain) NSArray *selectedItems;


- (NSDate *)fileCreationDate;
- (NSNumber *)fileSize;

@property (nonatomic, retain) NSPredicate *searchPredicate;



- (IBAction)installSourceAddon:(id)sender;

- (IBAction)find:(id)sender;
- (IBAction)findAdvanced:(id)sender;
- (IBAction)search:(id)sender;

- (IBAction)searchPredicateEditorChanged:(id)sender;

// path control methods
- (IBAction)revealInFinder:(id)sender;
- (IBAction)revealParentInFinder:(id)sender;


- (IBAction)switchViewMode:(id)sender;

- (IBAction)browserSelect:(id)sender;

// we define this method and intercept it so that our validateMenuItem: can properly update the menu item as long as a document is open.
- (IBAction)toggleShowQuickLook:(id)sender;
- (IBAction)toggleShowPathBar:(id)sender;


+ (NSArray *)orderedDocuments;


+ (BOOL)shouldShowViewOptions;
+ (void)setShouldShowViewOptions:(BOOL)shouldShow;

+ (BOOL)shouldShowInspector;
+ (void)setShouldShowInspector:(BOOL)shouldShow;

+ (BOOL)shouldShowQuickLook;
+ (void)setShouldShowQuickLook:(BOOL)shouldShow;

+ (BOOL)shouldShowPathBar;
+ (void)setShouldShowPathBar:(BOOL)shouldShow;


@end



extern NSString * const MDHLDocumentShouldShowInvisibleItemsKey;

extern NSString * const MDHLDocumentViewModeDidChangeNotification;
extern NSString * const MDHLDocumentViewModeKey;


extern NSString * const MDHLDocumentShouldShowViewOptionsKey;
extern NSString * const MDHLDocumentShouldShowViewOptionsDidChangeNotification;

extern NSString * const MDHLDocumentShouldShowInspectorKey;
extern NSString * const MDHLDocumentShouldShowInspectorDidChangeNotification;

extern NSString * const MDHLDocumentShouldShowQuickLookKey;
extern NSString * const MDHLDocumentShouldShowQuickLookDidChangeNotification;

extern NSString * const MDHLDocumentShouldShowPathBarKey;
extern NSString * const MDHLDocumentShouldShowPathBarDidChangeNotification;


extern NSString * const MDHLDocumentSelectedItemsDidChangeNotification;

extern NSString * const MDHLDocumentWillCloseNotification;


