//
//  MDHLDocument.m
//  Source Finagler
//
//  Created by Mark Douma on 1/30/2008.
//  Copyright © 2008 Mark Douma. All rights reserved.
//


#import "MDHLDocument.h"

#import <CoreServices/CoreServices.h>
#import <QTKit/QTKit.h>

#import <HLKit/HLKit.h>

#import "MDAppController.h"
#import "MDViewOptionsController.h"

#import "MDMetalBevelView.h"
#import "MDOutlineView.h"

#import "MDTextFieldCell.h"

#import "MDBrowser.h"
#import "MDBrowserCell.h"

#import "MDAppKitAdditions.h"

#import "MDUserDefaults.h"
#import "MDBottomBar.h"

#import "MDPreviewViewController.h"
#import "MDPathControlView.h"
#import "MDInspectorView.h"

#import "MDProcessManager.h"
#import "MDCopyOperation.h"
#import "MDCopyOperationController.h"

#import "MDFileSizeFormatter.h"



#define MD_DEBUG 1
#define MD_DEBUG_TABLE_COLUMNS 1



NSString * const MDHLDocumentErrorDomain									= @"MDHLDocumentErrorDomain";
NSString * const MDHLDocumentURLKey											= @"MDHLDocumentURL";


static NSString * const MDHLDocumentWindowSavedFrameKey						= @"MDHLDocumentWindowSavedFrame";


NSString * const MDHLDocumentShouldShowInvisibleItemsKey					= @"MDHLDocumentShouldShowInvisibleItems";

NSString * const MDHLDocumentViewModeDidChangeNotification					= @"MDHLDocumentViewModeDidChange";
NSString * const MDHLDocumentViewModeKey									= @"MDHLDocumentViewMode";

NSString * const MDHLDocumentShouldShowViewOptionsKey						= @"MDHLDocumentShouldShowViewOptions";
NSString * const MDHLDocumentShouldShowViewOptionsDidChangeNotification		= @"MDHLDocumentShouldShowViewOptionsDidChange";

NSString * const MDHLDocumentShouldShowInspectorKey							= @"MDHLDocumentShouldShowInspector";
NSString * const MDHLDocumentShouldShowInspectorDidChangeNotification		= @"MDHLDocumentShouldShowInspectorDidChange";

NSString * const MDHLDocumentShouldShowQuickLookKey							= @"MDHLDocumentShouldShowQuickLook";
NSString * const MDHLDocumentShouldShowQuickLookDidChangeNotification		= @"MDHLDocumentShouldShowQuickLookDidChange";

NSString * const MDHLDocumentShouldShowPathBarKey							= @"MDHLDocumentShouldShowPathBar";
NSString * const MDHLDocumentShouldShowPathBarDidChangeNotification			= @"MDHLDocumentShouldShowPathBarDidChange";

NSString * const MDHLDocumentSelectedItemsDidChangeNotification				= @"MDHLDocumentSelectedItemsDidChange";


static NSString * const MDSystemSoundEffectsBundleIdentifierKey				= @"com.apple.systemsound";
static NSString * const MDSystemSoundEffectsEnabledKey						= @"com.apple.sound.uiaudio.enabled";


NSString * const MDHLDocumentWillCloseNotification							= @"MDHLDocumentWillClose";



@interface MDHLDocument ()


+ (BOOL)shouldPlaySoundEffects;
+ (void)updateShouldPlaySoundEffects;


- (void)updateCount;

- (void)reloadOutlineViewData;

- (NSDictionary *)simplifiedItemsAndPathsForItems:(NSArray *)items resultingNames:(NSArray **)resultingNames;

- (NSArray *)namesOfPromisedFilesForItems:(NSArray *)selectedItems droppedAtDestination:(NSURL *)dropDestination;
- (BOOL)writeItems:(NSArray *)theItems toPasteboard:(NSPasteboard *)pboard;

@end


static NSInteger copyTag = 0;

static NSRecursiveLock *orderedDocumentsLock = nil;


// the following all used to be global variables in MDAppController

static BOOL shouldShowViewOptions = NO;
static BOOL shouldShowInspector = NO;
static BOOL shouldShowQuickLook = NO;
static BOOL shouldShowPathBar = NO;
static BOOL shouldPlaySoundEffects = NO;

static NSRecursiveLock *shouldShowViewOptionsLock = nil;
static NSRecursiveLock *shouldShowInspectorLock = nil;
static NSRecursiveLock *shouldShowQuickLookLock = nil;
static NSRecursiveLock *shouldShowPathBarLock = nil;
static NSRecursiveLock *shouldPlaySoundEffectsLock = nil;



@implementation MDHLDocument

@synthesize file;
@synthesize image;
@synthesize kind;
@synthesize version;
@synthesize viewMode;

@dynamic searchPredicate;
@dynamic selectedItems;


+ (void)initialize {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	static BOOL initialized = NO;
	
	@synchronized(self) {
		if (initialized == NO) {
			
			orderedDocumentsLock = [[NSRecursiveLock alloc] init];
			
			shouldShowViewOptionsLock = [[NSRecursiveLock alloc] init];
			shouldShowInspectorLock = [[NSRecursiveLock alloc] init];
			shouldShowQuickLookLock = [[NSRecursiveLock alloc] init];
			shouldShowPathBarLock = [[NSRecursiveLock alloc] init];
			shouldPlaySoundEffectsLock = [[NSRecursiveLock alloc] init];
			
			
			// cause MDOutlineView's and MDBrowser's +initialize methods to be called to initialize user defaults
			[MDOutlineView class];
			[MDBrowser class];
			
			[self updateShouldPlaySoundEffects];
			
			NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
			
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDHLDocumentShouldShowViewOptionsKey];
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDHLDocumentShouldShowInspectorKey];
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDHLDocumentShouldShowQuickLookKey];
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDHLDocumentShouldShowPathBarKey];
			
			[defaults setObject:[NSNumber numberWithBool:NO] forKey:MDHLDocumentShouldShowInvisibleItemsKey];
			
			[defaults setObject:[NSNumber numberWithInteger:MDHLDocumentListViewMode] forKey:MDHLDocumentViewModeKey];
			
			[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
			[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
			
			
			[self setShouldShowInspector:[[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowInspectorKey] boolValue]];
			[self setShouldShowViewOptions:[[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowViewOptionsKey] boolValue]];
			[self setShouldShowQuickLook:[[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowQuickLookKey] boolValue]];
			
			
			initialized = YES;
		}
	}
}


#pragma mark - "should show" Class methods

+ (BOOL)shouldPlaySoundEffects {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL shouldPlay = NO;
	[shouldPlaySoundEffectsLock lock];
	shouldPlay = shouldPlaySoundEffects;
	[shouldPlaySoundEffectsLock unlock];
	return shouldPlay;
}


+ (void)updateShouldPlaySoundEffects {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[NSProcessInfo processInfo] md__operatingSystemVersion].minorVersion >= MDLeopard) {
		NSNumber *enabled = [[MDUserDefaults standardUserDefaults] objectForKey:MDSystemSoundEffectsEnabledKey forAppIdentifier:MDSystemSoundEffectsBundleIdentifierKey inDomain:MDUserDefaultsUserDomain];
		
		/*	enabled is an NSNumber, not a YES or NO value. If enabled is nil, we assume the default sound effect setting, which is enabled. Only if enabled is non-nil do we have an actual YES or NO answer to examine	*/
		
		[shouldPlaySoundEffectsLock lock];
		
		if (enabled) {
			shouldPlaySoundEffects = (BOOL)[enabled intValue];
		} else {
			shouldPlaySoundEffects = YES;
		}
		[shouldPlaySoundEffectsLock unlock];
	}
}


+ (BOOL)shouldShowViewOptions {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL shouldShow = NO;
	[shouldShowViewOptionsLock lock];
	shouldShow = shouldShowViewOptions;
	[shouldShowViewOptionsLock unlock];
	return shouldShow;
}

+ (void)setShouldShowViewOptions:(BOOL)shouldShow {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[shouldShowViewOptionsLock lock];
	shouldShowViewOptions = shouldShow;
	[shouldShowViewOptionsLock unlock];
}


+ (BOOL)shouldShowInspector {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL shouldShow = NO;
	[shouldShowInspectorLock lock];
	shouldShow = shouldShowInspector;
	[shouldShowInspectorLock unlock];
	return shouldShow;
}

+ (void)setShouldShowInspector:(BOOL)shouldShow {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[shouldShowInspectorLock lock];
	shouldShowInspector = shouldShow;
	[shouldShowInspectorLock unlock];
}


+ (BOOL)shouldShowQuickLook {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL shouldShow = NO;
	[shouldShowQuickLookLock lock];
	shouldShow = shouldShowQuickLook;
	[shouldShowQuickLookLock unlock];
	return shouldShow;
}

+ (void)setShouldShowQuickLook:(BOOL)shouldShow {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[shouldShowQuickLookLock lock];
	shouldShowQuickLook = shouldShow;
	[shouldShowQuickLookLock unlock];
}


+ (BOOL)shouldShowPathBar {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	BOOL shouldShow = NO;
	[shouldShowPathBarLock lock];
	shouldShow = shouldShowPathBar;
	[shouldShowPathBarLock unlock];
	return shouldShow;
}

+ (void)setShouldShowPathBar:(BOOL)shouldShow {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[shouldShowPathBarLock lock];
	shouldShowPathBar = shouldShow;
	[shouldShowPathBarLock unlock];
}

#pragma mark -


- (id)init {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    
    if ((self = [super init])) {
		
		outlineViewIsSettingUpInitialColumns = YES;
		
		shouldShowInvisibleItems = [[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowInvisibleItemsKey] boolValue];
		
		searchResults = [[NSMutableArray alloc] init];
				
		copyOperationsAndTags = [[NSMutableDictionary alloc] init];
		
		[[self class] updateShouldPlaySoundEffects];
		
    } else {
		[self release];
		return nil;
	}
    return self;
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)outError {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@] type == \"%@\"", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), type);
#endif
	
	if (outError) *outError = nil;
		
	HKArchiveFileType archiveFileType = [HKArchiveFile archiveFileTypeForContentsOfFile:url.path];
	
	NSAssert(archiveFileType != HKArchiveFileNoType, @"archiveFileType != HKArchiveFileNoType");
	
	switch (archiveFileType) {
			
		case (HKArchiveFileGCFType) : {
			kind = [NSLocalizedString(@"Steam Cache file", @"") retain];
			file = [[HKGCFFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileVPKType) : {
			kind = [NSLocalizedString(@"Source Valve Package file", @"") retain];
			file = [[HKVPKFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileSGAType) : {
			kind = [NSLocalizedString(@"Source Game Archive", @"") retain];
			file = [[HKSGAFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileNCFType) : {
			kind = [NSLocalizedString(@"Steam Non-Cache file", @"") retain];
			file = [[HKNCFFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileBSPType) : {
			kind = [NSLocalizedString(@"Source Level", @"") retain];
			file = [[HKBSPFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
		case (HKArchiveFilePAKType) : {
			kind = [NSLocalizedString(@"Source Package file", @"") retain];
			file = [[HKPAKFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileWADType) : {
			kind = [NSLocalizedString(@"Source Texture Package file", @"") retain];
			file = [[HKWADFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		case (HKArchiveFileXZPType) : {
			kind = [NSLocalizedString(@"Source Xbox Package file", @"") retain];
			file = [[HKXZPFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
			
		default : {
			kind = [NSLocalizedString(@"Steam Cache file", @"") retain];
			file = [[HKGCFFile alloc] initWithContentsOfFile:[url path] showInvisibleItems:shouldShowInvisibleItems sortDescriptors:nil error:outError];
			break;
		}
	}
	
#if MD_DEBUG
	NSLog(@"[%@ %@] file == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), file);
#endif
	
	return (file != nil);
}
		

- (void)encodeWithCoder:(NSCoder *)coder {
	NSLog(@" \"%@\" [%@ %@] why the hell is this being called?", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
}

- (id)initWithCoder:(NSCoder *)coder {
	NSLog(@" \"%@\" [%@ %@] why the hell is this being called?", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	return nil;
}


- (void)dealloc {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	[outlineViewMenuShowQuickLookMenuItem release];
	
	[outlineViewMenuHelpMenuItem release];
	[outlineViewMenuShowInspectorMenuItem release];
	[outlineViewMenuShowViewOptionsMenuItem release];
	
	[browserMenuShowQuickLookMenuItem release];
	[browserMenuShowInspectorMenuItem release];
	[browserMenuShowViewOptionsMenuItem release];
	
	[actionButtonActionImageItem release];
	[actionButtonShowInspectorMenuItem release];
	[actionButtonShowQuickLookMenuItem release];
	[actionButtonShowViewOptionsMenuItem release];
	
	[file release];
	
	[copyOperationsAndTags release];
	
	[searchResults release];
	[searchPredicate release];
	
	[image release];
	
	[version release];
	
	[kind release];
	
	[super dealloc];
}


- (NSString *)windowNibName {
	if ([[NSProcessInfo processInfo] md__operatingSystemVersion].minorVersion >= MDSnowLeopard) {
		return @"MDHLDocumentLion";
	}
	return @"MDHLDocumentSnowLeopard";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    [super windowControllerDidLoadNib:aController];
	
	[scrollView setBorderType:NSNoBorder];
	
	[outlineView setTarget:self];
	[outlineView setDoubleAction:@selector(toggleShowQuickLook:)];
	
	
	[browser setDoubleAction:@selector(toggleShowQuickLook:)];
	
	[self setHasUndoManager:NO];
	
	outlineViewMenuShowQuickLookMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Look", @"") action:@selector(toggleShowQuickLook:) keyEquivalent:@""];
	
	[outlineViewMenuHelpMenuItem retain];
	[outlineViewMenuShowInspectorMenuItem retain];
	[outlineViewMenuShowViewOptionsMenuItem retain];
	

	if ([[NSProcessInfo processInfo] md__operatingSystemVersion].minorVersion >= MDSnowLeopard) {
		browserMenuShowQuickLookMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Look", @"") action:@selector(toggleShowQuickLook:) keyEquivalent:@""];
		[browserMenuShowInspectorMenuItem retain];
		[browserMenuShowViewOptionsMenuItem retain];
	}
	
	
	NSMenu *actionButtonMenu = [actionButton menu];
	
	if (actionButtonMenu) {
		if ([actionButtonMenu numberOfItems]) {
			actionButtonActionImageItem = [[[actionButton menu] itemAtIndex:0] retain];
		}
	}
	
	[actionButtonShowInspectorMenuItem retain];
	[actionButtonShowViewOptionsMenuItem retain];
	
	actionButtonShowQuickLookMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quick Look", @"") action:@selector(toggleShowQuickLook:) keyEquivalent:@""];
	
	if (searchToolbarItem) {
		[searchToolbarItem setMinSize:NSMakeSize(80.0,22.0)];
		[searchToolbarItem setMaxSize:NSMakeSize(230.0,22.0)];
	}
	
	[searchInspectorView setInitiallyShown:NO];
	[searchInspectorView setShown:NO];
	
	[[self class] setShouldShowPathBar:[[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowPathBarKey] boolValue]];
	
	[pathControlInspectorView setInitiallyShown:NO];
	
	[pathControl setURL:[self fileURL]];
	[pathControl setTarget:self];
	[pathControl setDoubleAction:@selector(revealInFinder:)];
	[pathControlInspectorView setShown:[[self class] shouldShowPathBar]];
		
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	viewMode = [[userDefaults objectForKey:MDHLDocumentViewModeKey] integerValue];
	
	/*	First swap in the appropriate view (outlineViewView or browserView) into the mainContentView, then set the window's size (frame) */
	
	if (viewMode == MDHLDocumentListViewMode) {
		[mainBox setContentView:outlineViewView];
		[hlWindow makeFirstResponder:outlineView];
	} else if (viewMode == MDHLDocumentColumnViewMode) {
		[mainBox setContentView:browserView];
		[hlWindow makeFirstResponder:browser];
	}
	
	if (viewSwitcherControl) {
		[viewSwitcherControl selectSegmentWithTag:viewMode];
	}
	
	NSString *savedFrame = [userDefaults objectForKey:MDHLDocumentWindowSavedFrameKey];
	if (savedFrame) [hlWindow setFrameFromString:savedFrame];
	
	if (file) {
		statusImageViewTag1 = [statusImageView1 addToolTipRect:[statusImageView1 visibleRect] owner:self userData:nil];
		statusImageViewTag2 = [statusImageView2 addToolTipRect:[statusImageView2 visibleRect] owner:self userData:nil];
	}
	
	
	/*		for preventing re-ordering of first table column	*/
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewColumnDidMove:) name:NSOutlineViewColumnDidMoveNotification object:outlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(browserSelectionDidChange:) name:MDBrowserSelectionDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowViewOptionsDidChange:) name:MDHLDocumentShouldShowViewOptionsDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowInspectorDidChange:) name:MDHLDocumentShouldShowInspectorDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowQuickLookDidChange:) name:MDHLDocumentShouldShowQuickLookDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(shouldShowPathBarDidChange:) name:MDHLDocumentShouldShowPathBarDidChangeNotification object:nil];
	
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@"[%@ %@] [outlineView sortDescriptors] == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [outlineView sortDescriptors]);
#endif
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDHLDocumentShouldShowInvisibleItemsKey]
																 options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	[[file items] setSortDescriptors:(viewMode == MDHLDocumentListViewMode ? [outlineView sortDescriptors] : [browser sortDescriptors]) recursively:YES];
	[[file items] recursiveSortChildren];
	
	if (viewMode == MDHLDocumentListViewMode) {
		[self reloadOutlineViewData];
	} else {
		[browser reloadData];
	}
	[self updateCount];
	
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[[self fileURL] path]];
	[icon setSize:NSMakeSize(128.0, 128.0)];
	image = [icon retain];
	version = [[file version] retain];
	
	[progressIndicator setUsesThreadedAnimation:YES];
	
	[self performSelector:@selector(setUpOutlineViewColumn:) withObject:nil afterDelay:1.0];
}


- (void)setUpOutlineViewColumn:(id)sender {
#if MD_DEBUG_TABLE_COLUMNS
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	outlineViewIsSettingUpInitialColumns = NO;
	
	/*		for preventing re-ordering of first table column	*/
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewColumnDidMove:) name:NSOutlineViewColumnDidMoveNotification object:outlineView];
	
}


- (id)valueForUndefinedKey:(NSString *)key {
#if MD_DEBUG
//	NSLog(@"[%@ %@] key == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), key);
#endif
	if ([key isEqualToString:@"compression"] || 
		[key isEqualToString:@"hasAlpha"] ||
		[key isEqualToString:@"hasMipmaps"] ||
		[key isEqualToString:@"movie"] ||
		[key isEqualToString:@"dimensions"]) {
		return nil;
	}
	return [super valueForUndefinedKey:key];
}


- (void)setShouldShowInvisibleItems:(BOOL)value {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	shouldShowInvisibleItems = value;
	[[file items] setShowInvisibleItems:shouldShowInvisibleItems];
	if (viewMode == MDHLDocumentListViewMode) {
		[self reloadOutlineViewData];
	} else if (viewMode == MDHLDocumentColumnViewMode) {
		[browser reloadData];
	}
	[self updateCount];
}

- (BOOL)shouldShowInvisibleItems {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return shouldShowInvisibleItems;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([keyPath isEqualToString:[NSString stringWithFormat:@"defaults.%@", MDHLDocumentShouldShowInvisibleItemsKey]]) {
		[self setShouldShowInvisibleItems:[[[NSUserDefaults standardUserDefaults] objectForKey:MDHLDocumentShouldShowInvisibleItemsKey] boolValue]];
		
	} else {
		if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
			// be sure to call the super implementation
			// if the superclass implements it
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
	}
}


+ (NSArray *)orderedDocuments {
	
	NSArray *orderedDocuments = nil;
	
	[orderedDocumentsLock lock];
	orderedDocuments = [[[NSApp orderedDocuments] copy] autorelease];
	[orderedDocumentsLock unlock];
	
#if MD_DEBUG
//	printf("\n\n");
//	NSLog(@"[%@ %@] orderedDocuments == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), orderedDocuments);
//	NSDocument *currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
//	NSLog(@"[%@ %@] currentDocument == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), currentDocument);
//	printf("\n\n");
#endif
	
	NSMutableArray *orderedMDHLDocuments = [NSMutableArray array];
	
	for (NSDocument *document in orderedDocuments) {
		if ([document isKindOfClass:[MDHLDocument class]]) {
			[orderedMDHLDocuments addObject:document];
		}
	}
	
	return [[orderedMDHLDocuments copy] autorelease];
}


- (BOOL)isFrontmostMDHLDocument {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	/* If our window is the main window, then we know without a doubt that we are the 
	 frontmost document, regardless of what the NSApp's orderedDocuments method returns 
	 (it sometimes appears to be out of order). */
	
	if ([hlWindow isMainWindow]) {
#if MD_DEBUG
//		NSLog(@" \"%@\" [%@ %@] ***** WE'RE the MAIN WINDOW *******", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		return YES;
	}
	
	NSArray *orderedDocuments = [[self class] orderedDocuments];
	
	if (orderedDocuments.count) {
		return ([orderedDocuments objectAtIndex:0] == self);
	}
	return NO;
}


#pragma mark - should show Notifications


- (void)shouldShowViewOptionsDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[self class] shouldShowViewOptions] && [self isFrontmostMDHLDocument]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentViewModeDidChangeNotification object:self userInfo:nil];
	}
}


- (void)shouldShowInspectorDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[self class] shouldShowInspector] && [self isFrontmostMDHLDocument]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentSelectedItemsDidChangeNotification object:self userInfo:nil];
	}
}


- (void)shouldShowQuickLookDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([[self class] shouldShowQuickLook] && [self isFrontmostMDHLDocument]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentSelectedItemsDidChangeNotification object:self userInfo:nil];
	}
}


- (void)shouldShowPathBarDidChange:(NSNotification *)notification {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[pathControlInspectorView setShown:[[self class] shouldShowPathBar]];
}


#pragma mark - key value coding

- (NSDate *)fileCreationDate {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[[NSFileManager alloc] init] autorelease] attributesOfItemAtPath:[[self fileURL] path] error:NULL] objectForKey:NSFileCreationDate];
}


- (NSNumber *)fileSize {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [[[[[NSFileManager alloc] init] autorelease] attributesOfItemAtPath:[[self fileURL] path] error:NULL] objectForKey:NSFileSize];
}


- (NSArray *)selectedItems {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (viewMode == MDHLDocumentListViewMode) {
		
		return [outlineView itemsAtRowIndexes:[outlineView selectedRowIndexes]];
		
	} else if (viewMode == MDHLDocumentColumnViewMode) {
		
		NSInteger selectedColumn = [browser selectedColumn];
		if (selectedColumn != -1) {
			return [browser itemsAtRowIndexes:[browser selectedRowIndexesInColumn:selectedColumn] inColumn:selectedColumn];
		}
	}
	return [NSArray array];
}


- (void)updateCount {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSIndexSet *selectedIndexes = nil;
	NSNumber *totalCount = nil;
	
	if (viewMode == MDHLDocumentListViewMode || isSearching) {
		
		selectedIndexes = [outlineView selectedRowIndexes];
		totalCount = [NSNumber numberWithUnsignedInteger:outlineViewItemCount];
		
	} else if (viewMode == MDHLDocumentColumnViewMode) {
		
		NSInteger targetColumn = -1;
		
		NSInteger selectedColumn = [browser selectedColumn];
		if (selectedColumn != -1) {
			selectedIndexes = [browser selectedRowIndexesInColumn:selectedColumn];
			NSUInteger selectedCount = [selectedIndexes count];
			if (selectedCount == 1) {
				HKItem *item = [browser itemAtRow:[selectedIndexes firstIndex] inColumn:selectedColumn];
				if ([item isLeaf]) {
					targetColumn = selectedColumn;
				} else {
					targetColumn = selectedColumn + 1;
					selectedIndexes = [NSIndexSet indexSet];
				}
			} else if (selectedCount > 1) {
				targetColumn = selectedColumn;
			}
			
			HKItem *parent = [browser parentForItemsInColumn:targetColumn];
			
			if (parent) {
				totalCount = [NSNumber numberWithUnsignedInteger:(NSUInteger) (shouldShowInvisibleItems ? [parent countOfChildNodes] : [parent countOfVisibleChildNodes])];
			} else {
				totalCount = [NSNumber numberWithUnsignedInteger:(NSUInteger) (shouldShowInvisibleItems ? [[file items] countOfChildNodes] : [[file items] countOfVisibleChildNodes])];
			}
		} else {
			totalCount = [NSNumber numberWithUnsignedInteger:(NSUInteger) (shouldShowInvisibleItems ? [[file items] countOfChildNodes] : [[file items] countOfVisibleChildNodes])];
		}
	}
	NSNumber *freeSpace = [[[[[NSFileManager alloc] init] autorelease] attributesOfFileSystemForPath:([self fileURL] ? [[self fileURL] path] : (file ? [file filePath] : @"/")) error:NULL] objectForKey:NSFileSystemFreeSize];
	
	[bottomBar setSelectedIndexes:selectedIndexes totalCount:totalCount freeSpace:freeSpace];
	
}



- (IBAction)find:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (searchField) {
		[searchField setEnabled:YES];
		[hlWindow makeFirstResponder:searchField];
	}
}

- (IBAction)findAdvanced:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (searchField) {
		[searchField setStringValue:@""];
		[searchField setEnabled:NO];
	}
	
	[searchInspectorView setShown:YES];
	
	if (isSearching == NO) {
		
		[searchResults removeAllObjects];
		
		[progressIndicator startAnimation:nil];
		
		[viewSwitcherControl selectSegmentWithTag:MDHLDocumentListViewMode];
		[viewSwitcherControl setEnabled:NO forSegment:1];
		
		isSearching	= YES;
		
		outlineViewItemCount = 0;
		
		[mainBox setContentView:outlineViewView];
		[outlineView deselectAll:self];
		
		[outlineView reloadData];
		
		[self updateCount];
	}
	
	[searchPredicateEditor addRow:self];
}

/* This method, the action of our predicate editor, is the one-stop-shop for all our updates.  We need to do potentially three things:
     1) Fire off a search if the user hit enter.
     2) Add some rows if the user deleted all of them, so the user isn't left without any rows.
     3) Resize the window if the number of rows changed (the user hit + or -).
*/

- (IBAction)searchPredicateEditorChanged:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	    /* This method gets called whenever the predicate editor changes, but we only want to create a new predicate when the user hits return.  So check NSApp currentEvent. */

    NSEvent *event = [NSApp currentEvent];
    if ([event type] == NSKeyDown) {
		NSString *characters = [event characters];
		if ([characters length] > 0 && [characters characterAtIndex:0] == 0x0D) {
			/* Get the predicate, which is the object value of our view. */
			[self setSearchPredicate:[searchPredicateEditor objectValue]];
			
			
			
		}
    }
	
    /* if the user deleted the first row, then add it again - no sense leaving the user with no rows */
    if ([searchPredicateEditor numberOfRows] == 0) [searchPredicateEditor addRow:self];
    
    /* resize the window vertically to accomodate our views */
        
    /* Get the new number of rows, which tells us the change in height.  Note that we can't just get the view frame, because it's currently animating - this method is called before the animation is finished. */
//    NSInteger newRowCount = [searchPredicateEditor numberOfRows];
    
    /* If there's no change in row count, there's no need to resize anything */
//    if (newRowCount == iPreviousRowCount) return;

    /* The autoresizing masks, by default, allows the outline view to grow and keeps the predicate editor fixed.  We need to temporarily grow the predicate editor, and keep the outline view fixed, so we have to change the autoresizing masks.  Save off the old ones; we'll restore them after changing the window frame. */
//    NSScrollView *outlineScrollView = [resultsOutlineView enclosingScrollView];
//    NSUInteger oldOutlineViewMask = [outlineScrollView autoresizingMask];
//    
//    NSScrollView *predicateEditorScrollView = [predicateEditor enclosingScrollView];
//    NSUInteger oldPredicateEditorViewMask = [predicateEditorScrollView autoresizingMask];
//    
//    [outlineScrollView setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
//    [predicateEditorScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
//        
//    /* Determine whether we're growing or shrinking... */
//    BOOL growing = (newRowCount > iPreviousRowCount);
//    
//    /* And figure out by how much.  Sizes must contain nonnegative values, which is why we avoid negative floats here. */
//    CGFloat heightDifference = fabs([predicateEditor rowHeight] * (newRowCount - iPreviousRowCount));
//    
//    /* Convert the size to window coordinates.  This is very important!  If we didn't do this, we would break under scale factors other than 1.  We don't care about the horizontal dimension, so leave that as 0. */
//    NSSize sizeChange = [predicateEditor convertSize:NSMakeSize(0, heightDifference) toView:nil];
//    
//    /* Change the window frame size.  If we're growing, the height goes up and the origin goes down (corresponding to growing down).  If we're shrinking, the height goes down and the origin goes up. */
//    NSRect windowFrame = [window frame];
//    windowFrame.size.height += growing ? sizeChange.height : -sizeChange.height;
//    windowFrame.origin.y -= growing ? sizeChange.height : -sizeChange.height;
//    [window setFrame:windowFrame display:YES animate:YES];
//    
//    /* restore the autoresizing mask */
//    [outlineScrollView setAutoresizingMask:oldOutlineViewMask];
//    [predicateEditorScrollView setAutoresizingMask:oldPredicateEditorViewMask];
//
//    /* record our new row count */
//    iPreviousRowCount = newRowCount;
	
	
}


- (IBAction)search:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *searchString = [searchField stringValue];
	
	if (searchString && ![searchString isEqualToString:@""]) {
		
		if (isSearching == NO) {
			
			[searchResults removeAllObjects];
			
			[progressIndicator startAnimation:nil];
			
			[viewSwitcherControl selectSegmentWithTag:MDHLDocumentListViewMode];
			[viewSwitcherControl setEnabled:NO forSegment:1];
			
			isSearching	= YES;
			
			outlineViewItemCount = 0;
			
			[mainBox setContentView:outlineViewView];
			[outlineView deselectAll:self];
			
			[outlineView reloadData];
			
			[self updateCount];
		}
		
		NSArray *allItems = [file allItems];
		
		[searchResults setArray:allItems];
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name contains[c] %@) OR (kind contains[c] %@)", searchString, searchString];
		if (predicate) {
			[searchResults filterUsingPredicate:predicate];
		}
		
		outlineViewItemCount = [searchResults count];
		
		[outlineView reloadData];
		
		[self updateCount];
		
		[progressIndicator stopAnimation:nil];
		
	} else {
		
		[searchResults removeAllObjects];
		
		[progressIndicator stopAnimation:nil];
		
		if (viewMode == MDHLDocumentListViewMode) {
			[mainBox setContentView:outlineViewView];
			[outlineView deselectAll:self];
		} else if (viewMode == MDHLDocumentColumnViewMode) {
			[mainBox setContentView:browserView];
			
		}
		
		[viewSwitcherControl selectSegmentWithTag:viewMode];
		[viewSwitcherControl setEnabled:YES forSegment:1];
		
		isSearching = NO;
		
		outlineViewItemCount = 0;
		
		if (viewMode == MDHLDocumentListViewMode) {
			[self reloadOutlineViewData];
		}
		[self updateCount];
		
	}
}


- (void)setSearchPredicate:(NSPredicate *)aPredicate {
#if MD_DEBUG
	NSLog(@"[%@ %@] aPredicate == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPredicate);
#endif
	[aPredicate retain];
	[searchPredicate release];
	searchPredicate = aPredicate;
	
	if (isSearching) {
		NSArray *allItems = [file allItems];
		
		[searchResults setArray:allItems];
		
		[searchResults filterUsingPredicate:searchPredicate];
		
		outlineViewItemCount = [searchResults count];
		
		[outlineView reloadData];
		
		[self updateCount];
		
		[progressIndicator stopAnimation:nil];
		
	}
	
}


- (NSPredicate *)searchPredicate {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return searchPredicate;
}


- (IBAction)installSourceAddon:(id)sender {
#if MD_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	// do nothing; subclasses can override
}


- (IBAction)browserSelect:(id)sender {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:MDBrowserSelectionDidChangeNotification object:browser userInfo:nil];
}


- (void)browserSelectionDidChange:(NSNotification *)notification {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if ([notification object] == browser) {
		
		[self updateCount];
		
		if ([self isFrontmostMDHLDocument]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentSelectedItemsDidChangeNotification object:self userInfo:nil];
		}
	}
}


#pragma mark -
#pragma mark <NSBrowserDelegate>

- (NSViewController *)browser:(NSBrowser *)aBrowser previewViewControllerForLeafItem:(id)item {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (![browser shouldShowPreview]) return nil;
	
	if (browserPreviewViewController == nil) {
		browserPreviewViewController = [[MDPreviewViewController alloc] init];
		[browserPreviewViewController loadView];
	}
	return browserPreviewViewController;
}


/* Return the number of children of the given item. */
- (NSInteger)browser:(NSBrowser *)aBrowser numberOfChildrenOfItem:(id)item {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@] item == %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), item);
#endif
	HKItem *node = (item == nil ? [file items] : item);
	if (node) return (shouldShowInvisibleItems ? [node countOfChildNodes] : [node countOfVisibleChildNodes]);
	return 0;
}


/* Return the indexth child of item. You may expect that index is never equal to or greater to the number of children of item as reported by -browser:numberOfChildrenOfItem:	*/
- (id)browser:(NSBrowser *)aBrowser child:(NSInteger)index ofItem:(id)item {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	HKItem *node = (item == nil ? [file items] : item);
	if (node) return (shouldShowInvisibleItems ? [node childNodeAtIndex:index] : [node visibleChildNodeAtIndex:index]);
	return nil;
}

/* Return whether item should be shown as a leaf item; that is, an item that can not be expanded into another column. Returning NO does not prevent you from returning 0 from -browser:numberOfChildrenOfItem:.
 */
- (BOOL)browser:(NSBrowser *)aBrowser isLeafItem:(id)item {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [(HKItem *)item isLeaf];
}


- (id)browser:(NSBrowser *)aBrowser objectValueForItem:(id)item {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [(HKItem *)item name];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)columnIndex {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	HKItem *item = [browser itemAtRow:row inColumn:columnIndex];
	if (item) {
		
		BOOL shouldShowIcons = [browser shouldShowIcons];
		
		NSInteger fontAndIconSize = [browser fontAndIconSize];
		if (shouldShowIcons) {
			NSImage *cellImage = [HKItem iconForItem:item];
			[cellImage setSize:NSMakeSize((CGFloat)(fontAndIconSize + 4.0), (CGFloat)(fontAndIconSize + 4.0))];
			[cell setImage:cellImage];
		} else {
			[cell setImage:nil];
		}
		
		[cell setFont:[NSFont systemFontOfSize:(CGFloat)fontAndIconSize]];
		[(MDBrowserCell *)cell setItemIsInvisible:![item isExtractable]];
	}
}


- (void)browser:(MDBrowser *)aBrowser sortDescriptorsDidChange:(NSArray *)oldDescriptors {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[file items] setSortDescriptors:[browser sortDescriptors] recursively:YES];
	[[file items] recursiveSortChildren];
	[browser reloadData];
}

#pragma mark <NSBrowserDelegate> END

#pragma mark -
#pragma mark NSBrowser <NSDraggingSource>

- (BOOL)browser:(NSBrowser *)aBrowser writeRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)columnIndex toPasteboard:(NSPasteboard *)pboard {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSArray *selectedItems = [browser itemsAtRowIndexes:rowIndexes inColumn:columnIndex];
	return [self writeItems:selectedItems toPasteboard:pboard];
}


- (NSArray *)browser:(NSBrowser *)aBrowser namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)rowIndexes inColumn:(NSInteger)columnIndex {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self namesOfPromisedFilesForItems:[browser itemsAtRowIndexes:rowIndexes inColumn:columnIndex] droppedAtDestination:dropDestination];
}


#pragma mark NSBrowser <NSDraggingSource> END
#pragma mark -


- (void)reloadOutlineViewData {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	outlineViewIsReloadingData = YES;
	[outlineView reloadData];
	outlineViewIsReloadingData = NO;
}


#pragma mark - <NSOutlineViewDataSource>


- (NSInteger)outlineView:(NSOutlineView *)anOutlineView numberOfChildrenOfItem:(id)item {
	HKItem *node = nil;
	
	if (item == nil) {
		
		if (isSearching) {
			return [searchResults count];
		} else {
			outlineViewItemCount = 0;
			node = [file items];
			if (node) {
				outlineViewItemCount += (shouldShowInvisibleItems ? [node countOfChildNodes] : [node countOfVisibleChildNodes]);
			}
		}
		
	} else {
		node = item;
		if (outlineViewIsReloadingData) {
			outlineViewItemCount += (shouldShowInvisibleItems ? [node countOfChildNodes] : [node countOfVisibleChildNodes]);
		}
	}
	if (node) {
		return (shouldShowInvisibleItems ? [node countOfChildNodes] : [node countOfVisibleChildNodes]);
	}
	return 0;
	
}


- (id)outlineView:(NSOutlineView *)anOutlineView child:(NSInteger)index ofItem:(id)item {
	HKItem *node = nil;
	
	if (item == nil) {
		if (isSearching) {
			return [searchResults objectAtIndex:index];
		} else {
			node = [file items];
		}
	} else {
		node = item;
	}
	if (node) {
		return (shouldShowInvisibleItems ? [node childNodeAtIndex:index] : [node visibleChildNodeAtIndex:index]);
	}
	return nil;
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView isItemExpandable:(id)item {
	HKItem *node = nil;
	
	if (item == nil) {
		if (isSearching) {
			return NO;
		} else {
			node = [file items];
			
		}
	} else {
		node = item;
	}
	
	if (node) {
		return ![node isLeaf];
	}
	return NO;
}

- (id)outlineView:(NSOutlineView *)anOutlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [item valueForKey:[tableColumn identifier]];
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView isGroupItem:(id)item {
	return NO;
}


#pragma mark <NSOutlineViewDataSource> END
#pragma mark -
#pragma mark <NSOutlineViewDelegate>


- (void)outlineView:(NSOutlineView *)anOutlineView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
	
	if (aTableColumn == nameColumn) {
		
		NSImage *cellImage = [HKItem iconForItem:item];
		
		NSInteger iconSize = [(MDOutlineView *)outlineView iconSize];
		NSSize imageSize = [cellImage size];
		if (imageSize.width != iconSize) {
			[cellImage setSize:NSMakeSize(iconSize, iconSize)];
		}
		[(MDTextFieldCell *)aCell setImage:cellImage];
		[aCell setEnabled:[item isExtractable]];
	}
}
	

// good

- (void)outlineView:(NSOutlineView *)anOutlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (isSearching) {
		NSArray *newDescriptors = [outlineView sortDescriptors];
		
		NSArray *selectedItems = [outlineView itemsAtRowIndexes:[outlineView selectedRowIndexes]];
		
		[searchResults sortUsingDescriptors:newDescriptors];
		
		[anOutlineView reloadData];
		
		[anOutlineView selectRowIndexes:[outlineView rowIndexesForItems:selectedItems] byExtendingSelection:NO];
		
	} else {
		
		NSArray *newDescriptors = [anOutlineView sortDescriptors];
		
		NSArray *selectedItems = [outlineView itemsAtRowIndexes:[outlineView selectedRowIndexes]];
		
		[[file items] setSortDescriptors:newDescriptors recursively:YES];
		[[file items] recursiveSortChildren];
		[self reloadOutlineViewData];
		
		[outlineView selectRowIndexes:[outlineView rowIndexesForItems:selectedItems] byExtendingSelection:NO];
	}
	
}


/*		to prevent re-ordering of first table column	*/
- (void)tableView:(NSTableView *)aTableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)aTableColumn {
#if MD_DEBUG_TABLE_COLUMNS
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (aTableColumn == nameColumn) {
		[aTableView setAllowsColumnReordering:NO];
	} else {
		[aTableView setAllowsColumnReordering:YES];
	}
}


- (void)outlineViewColumnDidMove:(NSNotification *)notification {
	if (outlineViewIsSettingUpInitialColumns == NO) {
		if (notification.object == outlineView) {
#if MD_DEBUG_TABLE_COLUMNS
			NSLog(@" \"%@\" [%@ %@] notification == %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), notification);
#endif
			NSDictionary *userInfo = [notification userInfo];
			
			if ([[userInfo objectForKey:@"NSOldColumn"] intValue] == 0) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewColumnDidMoveNotification object:outlineView];
				
				[outlineView moveColumn:[[userInfo objectForKey:@"NSNewColumn"] intValue] toColumn:0];
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewColumnDidMove:) name:NSOutlineViewColumnDidMoveNotification object:outlineView];
				
			} else if ([[userInfo objectForKey:@"NSNewColumn"] intValue] == 0) {
				[[NSNotificationCenter defaultCenter] removeObserver:self name:NSOutlineViewColumnDidMoveNotification object:outlineView];
				
				[outlineView moveColumn:0 toColumn:[[userInfo objectForKey:@"NSOldColumn"] intValue]];
				
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewColumnDidMove:) name:NSOutlineViewColumnDidMoveNotification object:outlineView];
			}
		}
	} else {
#if MD_DEBUG_TABLE_COLUMNS
		NSLog(@" \"%@\" [%@ %@] *** IGNORING ***", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
	}
}
/*		to prevent re-ordering of first table column	*/



- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification {
	
	if (viewMode == MDHLDocumentListViewMode || isSearching) {
		[self updateCount];
		
		if ([self isFrontmostMDHLDocument]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentSelectedItemsDidChangeNotification object:self userInfo:nil];
		}
	}
}
	

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *userInfo = [notification userInfo];
	HKItem *item = [userInfo objectForKey:@"NSObject"];
	outlineViewItemCount += (shouldShowInvisibleItems ? [item countOfChildNodes] : [item countOfVisibleChildNodes]);
	[self updateCount];
}


- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
#if MD_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	NSDictionary *userInfo = [notification userInfo];
	HKItem *item = [userInfo objectForKey:@"NSObject"];
	outlineViewItemCount -= (shouldShowInvisibleItems ? [item countOfChildNodes] : [item countOfVisibleChildNodes]);
	[self updateCount];
}

// =========================  NSTableView methods  (dragging related)  ==========================



#pragma mark <NSOutlineViewDelegate> END
#pragma mark -
#pragma mark NSOutlineView <NSDraggingSource>

- (BOOL)outlineView:(NSOutlineView *)anOutlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self writeItems:items toPasteboard:pboard];
}


- (NSArray *)outlineView:(NSOutlineView *)anOutlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedItems:(NSArray *)items {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [self namesOfPromisedFilesForItems:items droppedAtDestination:dropDestination];
}


#pragma mark NSOutlineView <NSDraggingSource> END
#pragma mark -
#pragma mark <NSDraggingSource>

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@] ************************************** END of drag operation **************************************", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
}

#pragma mark <NSDraggingSource> END


- (BOOL)writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, nil] owner:self];
	
	NSMutableArray *types = [NSMutableArray array];
	for (HKItem *item in items) {
		if ([item isKindOfClass:[HKFile class]]) {
			NSString *filenameExtension = [[item name] pathExtension];
			if (![types containsObject:filenameExtension]) {
				[types addObject:filenameExtension];
			}
		} else if ([item isKindOfClass:[HKFolder class]]) {
			NSString *folderType = NSFileTypeForHFSTypeCode(kGenericFolderIcon);
			if (![types containsObject:folderType]) {
				[types addObject:folderType];
			}
		}
	}
	[pboard setPropertyList:types forType:NSFilesPromisePboardType];
	return YES;
}


- (NSArray *)namesOfPromisedFilesForItems:(NSArray *)items droppedAtDestination:(NSURL *)dropDestination {
	NSArray *resultingNames = nil;
	
	NSString *targetPath = [dropDestination path];
	
	if (items && [items count]) {
		
#if MD_DEBUG
		NSDate *startDate = [NSDate date];
#endif
		
		NSDictionary *simplifiedItemsAndPaths = [self simplifiedItemsAndPathsForItems:items resultingNames:&resultingNames];
		
#if MD_DEBUG
		NSTimeInterval elapsedTime = fabs([startDate timeIntervalSinceNow]);
		NSLog(@"[%@ %@] elapsed time to gather %lu item(s) == %.7f sec / %.4f ms", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[simplifiedItemsAndPaths count], elapsedTime, elapsedTime * 1000.0);
#endif
		
		if (simplifiedItemsAndPaths == nil) {
			return nil;
		}
		
		// start copying process
		NSInteger ourCopyTag = 0;
		
		NSLock *lock = [[NSLock alloc] init];
		[lock lock];
		copyTag++;
		ourCopyTag = copyTag;
		[lock unlock];
		[lock release];
		
		MDCopyOperation *copyOperation = [MDCopyOperation operationWithSource:self destination:targetPath itemsAndPaths:simplifiedItemsAndPaths tag:ourCopyTag];
		if (copyOperation == nil) {
			return nil;
		}
		
		@synchronized(copyOperationsAndTags) {
			[copyOperationsAndTags setObject:copyOperation forKey:[NSNumber numberWithInteger:ourCopyTag]];
		}
		
		[[MDCopyOperationController sharedController] addOperation:copyOperation];
		
		[self performSelector:@selector(beginCopyOperationWithTag:) withObject:[NSNumber numberWithInteger:ourCopyTag] afterDelay:0.0];
		
	}	
	return resultingNames;
}


- (void)beginCopyOperationWithTag:(NSNumber *)aTag {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[NSThread detachNewThreadSelector:@selector(performCopyOperationWithTagInBackground:) toTarget:self withObject:aTag];
}

#define MD_PROGRESS_UPDATE_TIME_INTERVAL 0.5


- (void)performCopyOperationWithTagInBackground:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *currentThread = [NSThread currentThread];
	[currentThread setName:[NSString stringWithFormat:@"copyThread %@", sender]];
	
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@] - %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), [currentThread name]);
#endif
	MDCopyOperation *copyOperation = nil;
	
	@synchronized(copyOperationsAndTags) {
		copyOperation = [[[copyOperationsAndTags objectForKey:sender] retain] autorelease];
	}
	
	if (copyOperation) {
		id destination = [copyOperation destination];
		if ([destination isKindOfClass:[NSString class]]) {
			destination = (NSString *)destination;
			
			NSDictionary *itemsAndPaths = [copyOperation itemsAndPaths];
			NSArray *allItems = [itemsAndPaths allValues];
			
			unsigned long long totalBytes = 0;
			unsigned long long currentBytes = 0;
			
#if MD_DEBUG
			NSDate *startDate = [NSDate date];
#endif
			
			for (HKItem *item in allItems) {
				if ([item isLeaf]) {
					totalBytes += [[item size] unsignedLongLongValue];
				}
			}
			
#if MD_DEBUG
			NSTimeInterval elapsedTime = fabs([startDate timeIntervalSinceNow]);
			NSLog(@"[%@ %@] elapsed time to size %lu items == %.7f sec / %.4f ms", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)[allItems count], elapsedTime, elapsedTime * 1000.0);
#endif
			
			NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										copyOperation,MDCopyOperationKey,
										[NSNumber numberWithUnsignedInteger:MDCopyOperationPreparingStage],MDCopyOperationStageKey,
										destination,MDCopyOperationDestinationKey,
										 [NSNumber numberWithUnsignedInteger:[allItems count]],MDCopyOperationTotalItemCountKey, nil];
										
			[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
			
			NSDate *progressDate = [[NSDate date] retain];
			
			NSUInteger totalItemCount = [allItems count];
			NSUInteger currentItemIndex = 0;
			
			NSArray *relativeDestinationPaths = [itemsAndPaths allKeys];
			
			for (NSString *relativeDestinationPath in relativeDestinationPaths) {
				
				if ([copyOperation isCancelled]) {
					
					[progressDate release];

					NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
												copyOperation,MDCopyOperationKey,
												[NSNumber numberWithUnsignedLongLong:totalBytes],MDCopyOperationTotalBytesKey,
												[NSNumber numberWithUnsignedLongLong:currentBytes],MDCopyOperationCurrentBytesKey,
												[NSNumber numberWithUnsignedInteger:MDCopyOperationCancelledStage],MDCopyOperationStageKey, nil];
					
					[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
					
					return;
				}
				
				
				if (ABS([progressDate timeIntervalSinceNow]) > MD_PROGRESS_UPDATE_TIME_INTERVAL) {
					
					NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
												copyOperation,MDCopyOperationKey,
												[NSNumber numberWithUnsignedInteger:MDCopyOperationCopyingStage],MDCopyOperationStageKey,
												destination,MDCopyOperationDestinationKey,
												[NSNumber numberWithUnsignedLongLong:totalBytes],MDCopyOperationTotalBytesKey,
												[NSNumber numberWithUnsignedLongLong:currentBytes],MDCopyOperationCurrentBytesKey,
												[NSNumber numberWithUnsignedInteger:totalItemCount],MDCopyOperationTotalItemCountKey,
												[NSNumber numberWithUnsignedInteger:currentItemIndex],MDCopyOperationCurrentItemIndexKey, nil];
					
					[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
					
					
					[progressDate release];
					progressDate = [[NSDate date] retain];
				}
				
				
				HKItem *item = [itemsAndPaths objectForKey:relativeDestinationPath];
				
				NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
				
				NSString *destinationPath = [(NSString *)destination stringByAppendingPathComponent:relativeDestinationPath];
				
				NSError *outError = nil;
				
				if ([item isLeaf]) {
					
					if (![(HKFile *)item beginWritingToFile:destinationPath assureUniqueFilename:YES resultingPath:NULL error:&outError]) {
						NSLog(@" \"%@\" [%@ %@] - (%@) beginWritingToFile: for %@ failed!", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), [currentThread name], destinationPath);
						continue;
					}
					
					while (1) {
						
						if ([copyOperation isCancelled]) {
							if (![(HKFile *)item cancelWritingAndRemovePartialFileWithError:&outError]) {
								
							}
							
							[progressDate release];
							
							NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
														copyOperation,MDCopyOperationKey,
														[NSNumber numberWithUnsignedLongLong:totalBytes],MDCopyOperationTotalBytesKey,
														[NSNumber numberWithUnsignedLongLong:currentBytes],MDCopyOperationCurrentBytesKey,
														[NSNumber numberWithUnsignedInteger:MDCopyOperationCancelledStage],MDCopyOperationStageKey, nil];
							
							[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
							
							[localPool release];
							
							return;
						}
						
						NSUInteger partialBytesLength = 0;
						
						if (![(HKFile *)item continueWritingPartialBytesOfLength:&partialBytesLength error:&outError]) {
							break;
						}
						
						currentBytes += partialBytesLength;
						
						if (ABS([progressDate timeIntervalSinceNow]) > MD_PROGRESS_UPDATE_TIME_INTERVAL) {
							
							NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
														copyOperation,MDCopyOperationKey,
														[NSNumber numberWithUnsignedInteger:MDCopyOperationCopyingStage],MDCopyOperationStageKey,
														destination,MDCopyOperationDestinationKey,
														[NSNumber numberWithUnsignedLongLong:totalBytes],MDCopyOperationTotalBytesKey,
														[NSNumber numberWithUnsignedLongLong:currentBytes],MDCopyOperationCurrentBytesKey,
														[NSNumber numberWithUnsignedInteger:totalItemCount],MDCopyOperationTotalItemCountKey,
														[NSNumber numberWithUnsignedInteger:currentItemIndex],MDCopyOperationCurrentItemIndexKey, nil];
							
							[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
							
							[progressDate release];
							progressDate = [[NSDate date] retain];
						}
					}
					
					if (![(HKFile *)item finishWritingWithError:&outError]) {
						NSLog(@" \"%@\" [%@ %@] - (%@) finishWritingWithError: for %@ failed!", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), [currentThread name], destinationPath);
					}
					
				} else {
					if (![item writeToFile:destinationPath assureUniqueFilename:YES resultingPath:NULL error:&outError]) {
						NSLog(@" \"%@\" [%@ %@] - (%@) writeToFile: for %@ failed!", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), [currentThread name], destinationPath);
					}
				}
				
				currentItemIndex++;
				
				[localPool release];
				
			}
			
			[progressDate release];
			
			dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										copyOperation,MDCopyOperationKey,
										[NSNumber numberWithUnsignedLongLong:totalBytes],MDCopyOperationTotalBytesKey,
										[NSNumber numberWithUnsignedLongLong:currentBytes],MDCopyOperationCurrentBytesKey,
										[NSNumber numberWithUnsignedInteger:MDCopyOperationFinishingStage],MDCopyOperationStageKey, nil];
			
			[self performSelectorOnMainThread:@selector(updateProgressWithDictionary:) withObject:dictionary waitUntilDone:NO];
			
		}
	}
	[pool release];
}



- (void)updateProgressWithDictionary:(NSDictionary *)dictionary {
	
	static MDFileSizeFormatter *fileSizeFormatter = nil;

	if (fileSizeFormatter == nil) fileSizeFormatter = [[MDFileSizeFormatter alloc] initWithUnitsType:MDFileSizeFormatterAutomaticUnitsType style:MDFileSizeFormatterPhysicalStyle];
	
	MDCopyOperation *copyOperation = [dictionary objectForKey:MDCopyOperationKey];
	if (copyOperation) {
		MDCopyOperationStage stage = [[dictionary objectForKey:MDCopyOperationStageKey] unsignedIntegerValue];
		
		if (stage == MDCopyOperationPreparingStage) {
			NSString *destination = [[dictionary objectForKey:MDCopyOperationDestinationKey] lastPathComponent];
			[copyOperation setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Preparing to copy to \"%@\"", @""), [destination lastPathComponent]]];
			
			NSUInteger totalItemCount = [[dictionary objectForKey:MDCopyOperationTotalItemCountKey] unsignedIntegerValue];
			
			if (totalItemCount == 1) {
				[copyOperation setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Preparing to copy %lu item", @""), (unsigned long)totalItemCount]];
				
			} else {
				[copyOperation setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Preparing to copy %lu items", @""), (unsigned long)totalItemCount]];
			}
			
			
		} else if (stage == MDCopyOperationCopyingStage) {
			
			if ([copyOperation indeterminate]) {
				[copyOperation setTotalBytes:(double)[[dictionary objectForKey:MDCopyOperationTotalBytesKey] unsignedLongLongValue]];
				[copyOperation setCurrentBytes:0.0];
				[copyOperation setIndeterminate:NO];
			}			
			
			[copyOperation setCurrentBytes:(double)[[dictionary objectForKey:MDCopyOperationCurrentBytesKey] unsignedLongLongValue]];
			
			NSString *destination = [[dictionary objectForKey:MDCopyOperationDestinationKey] lastPathComponent];
			
			NSUInteger totalItemCount = [[dictionary objectForKey:MDCopyOperationTotalItemCountKey] unsignedIntegerValue];
			NSUInteger currentItemIndex = [[dictionary objectForKey:MDCopyOperationCurrentItemIndexKey] unsignedIntegerValue];
			
			NSNumber *totalBytes = [dictionary objectForKey:MDCopyOperationTotalBytesKey];
			NSNumber *currentBytes = [dictionary objectForKey:MDCopyOperationCurrentBytesKey];
			
			if (totalItemCount == 1) {
				[copyOperation setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Copying %lu item to \"%@\"", @""), (unsigned long)(totalItemCount - currentItemIndex), destination]];
			} else {
				[copyOperation setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Copying %lu items to \"%@\"", @""), (unsigned long)(totalItemCount - currentItemIndex), destination]];
			}
			
			[copyOperation setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ of %@", @""), [fileSizeFormatter stringForObjectValue:currentBytes],
											   [fileSizeFormatter stringForObjectValue:totalBytes]]];
			
		} else if (stage == MDCopyOperationFinishingStage) {
			[copyOperation setCurrentBytes:(double)[[dictionary objectForKey:MDCopyOperationCurrentBytesKey] unsignedLongLongValue]];
			[copyOperation setMessageText:@""];
			[copyOperation setInformativeText:@""];
			
			[[MDCopyOperationController sharedController] endOperation:copyOperation];
			
			if ([[self class] shouldPlaySoundEffects]) [(NSSound *)[NSSound soundNamed:@"copy"] play];
			
			@synchronized(copyOperationsAndTags) {
				[copyOperationsAndTags removeObjectForKey:[NSNumber numberWithInteger:[copyOperation tag]]];
			}
			
		} else if (stage == MDCopyOperationCancelledStage) {
			[copyOperation setMessageText:@""];
			[copyOperation setInformativeText:@""];
			
			[[MDCopyOperationController sharedController] endOperation:copyOperation];
			
			if ([[self class] shouldPlaySoundEffects]) [(NSSound *)[NSSound soundNamed:@"copy"] play];
			
			@synchronized(copyOperationsAndTags) {
				[copyOperationsAndTags removeObjectForKey:[NSNumber numberWithInteger:[copyOperation tag]]];
			}
		}
	}
}

- (NSDictionary *)simplifiedItemsAndPathsForItems:(NSArray *)items resultingNames:(NSArray **)resultingNames {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@] items == %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), items);
#endif
	if (resultingNames) *resultingNames = nil;
	if (items == nil) return nil;
	
	NSMutableArray *resultingFilenames = [NSMutableArray array];
	
	NSMutableArray *rootItems = [NSMutableArray array];
	
	NSMutableDictionary *allItemsAndPaths = [NSMutableDictionary dictionary];
	
	[rootItems addObjectsFromArray:items];
	
	for (HKItem *item in items) {
		for (HKItem *innerItem in items) {
			if (item != innerItem) {
				if ([innerItem isDescendantOfNode:item]) {
					[rootItems removeObject:innerItem];
				}
			}
		}
	}
	
	for (HKItem *item in rootItems) {
		
		[allItemsAndPaths setObject:item forKey:[item pathRelativeToItem:(HKItem *)[item parent]]];
		
		if (![item isLeaf]) {
			NSDictionary *descendentsAndPaths = [(HKFolder *)item visibleDescendantsAndPathsRelativeToItem:(HKItem *)[item parent]];
			if (descendentsAndPaths) [allItemsAndPaths addEntriesFromDictionary:descendentsAndPaths];
		}
	}
	
	if (resultingNames) {
		NSArray *relativeDestinationPaths = [allItemsAndPaths allKeys];
		
		for (NSString *relativeDestinationPath in relativeDestinationPaths) {
			if ([[relativeDestinationPath pathComponents] count] == 1) {
				[resultingFilenames addObject:[relativeDestinationPath lastPathComponent]];
			}
		}
		*resultingNames = [[resultingFilenames copy] autorelease];
	}
	return [[allItemsAndPaths copy] autorelease];
}


#pragma mark -

- (IBAction)revealInFinder:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([pathControl clickedPathComponentCell]) {
		[[NSWorkspace sharedWorkspace] openURL:[[pathControl clickedPathComponentCell] URL]];
	}
}


- (IBAction)revealParentInFinder:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ([pathControl clickedPathComponentCell]) {
		NSURL *originalURL = nil;
		originalURL = [[pathControl clickedPathComponentCell] URL];
		if (originalURL) {
			NSString *originalPath = [originalURL path];
			if (originalPath) {
				NSString *parentDir = [originalPath stringByDeletingLastPathComponent];
				NSURL *parentURL = [NSURL fileURLWithPath:parentDir];
				if (parentURL) {
					[[NSWorkspace sharedWorkspace] openURL:parentURL];
				}
			}
		}
	}
}


- (HKArchiveFile *)file {
	return file;
}


#pragma mark - <NSWindowDelegate>


- (void)windowDidBecomeMain:(NSNotification *)notification {
	
	if ([notification object] == hlWindow) {
		
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		[[self class] orderedDocuments];
#endif
		
		/*	this is for the viewOptionsController, so it can do its switching	*/
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentViewModeDidChangeNotification object:self userInfo:nil];

		[self updateCount];
		
		if (pathControl) {
			[pathControl setBackgroundColor:[NSColor colorWithCalibratedRed:222.0/255.0 green:228.0/255.0 blue:234.0/255.0 alpha:1.0]];
		}
		
		/* this is for the Inspector Controller and Quick Look Controller */
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentSelectedItemsDidChangeNotification object:self userInfo:nil];
		
	}
}


- (void)windowDidResignMain:(NSNotification *)notification {
	if ([notification object] == hlWindow) {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (pathControl) {
			[pathControl setBackgroundColor:[NSColor colorWithCalibratedRed:237.0/255.0 green:237.0/255.0 blue:237.0/255.0 alpha:1.0]];
		}
	}
}


- (void)windowWillClose:(NSNotification *)notification {
	
	if ([notification object] == hlWindow) {
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		[[NSUserDefaults standardUserDefaults] setObject:[hlWindow stringWithSavedFrame] forKey:MDHLDocumentWindowSavedFrameKey];
		
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[NSString stringWithFormat:@"defaults.%@", MDHLDocumentShouldShowInvisibleItemsKey]];
		
//		[browserPreviewViewController cleanup];
		[browserPreviewViewController release];
		browserPreviewViewController = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentWillCloseNotification object:self userInfo:nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}	
}

#pragma mark END <NSWindowDelegate>
#pragma mark -

- (IBAction)switchViewMode:(id)sender {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
// TODO: try to preserve selection and navigation level when switching view mode
	
	NSInteger tag = -1;
	
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		NSInteger selectedSegment = [(NSSegmentedControl *)sender selectedSegment];
		tag = [(NSSegmentedCell *)[sender cell] tagForSegment:selectedSegment];
		
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] tag == %ld", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)tag);
#endif
	} else {
		tag = [sender tag];
	}
	
	if (tag != viewMode) {
		
		if (tag == MDHLDocumentListViewMode) {
			
			/* get current browser selection, select items in outline view, then switch view to outline view, then deselect items in browser */
			
#if MD_DEBUG
			NSArray *selectionIndexPaths = [browser selectionIndexPaths];
			NSLog(@"[%@ %@] selectionIndexPaths == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), selectionIndexPaths);
#endif
			
			[[file items] setSortDescriptors:[outlineView sortDescriptors]];
			[[file items] recursiveSortChildren];
				
//			NSIndexSet *selectedRowIndexes = [browser selectedRowIndexesInColumn:0];
//			NSArray *selectedItems = [[self filteredItems] objectsAtIndexes:selectedRowIndexes];
//			
//			[[self filteredItems] sortUsingDescriptors:[outlineView sortDescriptors]];
			
			/* change the view mode earlier, so that when I issue the deselectAll: command below, we won't care about it */
			
			viewMode = tag;
			
//			if ([selectedItems count] > 0) {
//				NSMutableIndexSet *newSelectedRowIndexes = [NSMutableIndexSet indexSet];
//				NSEnumerator *enumerator = [selectedItems objectEnumerator];
//				HKItem *item;
//				
//				while (item = [enumerator nextObject]) {
//					[newSelectedRowIndexes addIndex:[[self filteredItems] indexOfObject:item]];
//				}
//				
//				[outlineView selectRowIndexes:newSelectedRowIndexes byExtendingSelection:NO];
//			}
				
			[viewSwitcherControl selectSegmentWithTag:tag];
			
			/* I'll always need to reloadData, since I've just sorted the [file items] array differently */
			[self reloadOutlineViewData];
			
			[hlWindow makeFirstResponder:outlineView];
			[mainBox setContentView:outlineViewView];
			[browser deselectAll:nil];
			
		} else if (tag == MDHLDocumentColumnViewMode) {
			
			/* get current outline view selection, select items in browser, then swtich view to browser, then deselect items in outline view */
			
			[[file items] setSortDescriptors:[browser sortDescriptors]];
			[[file items] recursiveSortChildren];
			
			
//			NSIndexSet *selectedRowIndexes = [outlineView selectedRowIndexes];
//			NSArray *selectedItems = [[self filteredItems] objectsAtIndexes:selectedRowIndexes];
//			
//			[[self filteredItems] sortUsingDescriptors:browserSortDescriptors];
			
			/* change the view mode earlier, so that when I issue the deselectAll: command below, we won't care about it */
			
			viewMode = tag;
			
//			[browser reloadDataPreservingSelection:NO];
			
//			if ([selectedItems count] > 0) {
//				NSMutableIndexSet *newSelectedRowIndexes = [NSMutableIndexSet indexSet];
//				NSEnumerator *enumerator = [selectedItems objectEnumerator];
//				HKItem *item;
//				
//				while (item = [enumerator nextObject]) {
//					[newSelectedRowIndexes addIndex:[[self filteredItems] indexOfObject:item]];
//				}
//				
//				[browser selectRowIndexes:newSelectedRowIndexes inColumn:0];
//			}
			
			[viewSwitcherControl selectSegmentWithTag:tag];
			
			
			/* I'll always need to reloadData, since I've just sorted the [file items] array differently */
			
			[hlWindow makeFirstResponder:browser];
			
			[mainBox setContentView:browserView];
			[outlineView deselectAll:nil];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:viewMode] forKey:MDHLDocumentViewModeKey];
		
		if ([self isFrontmostMDHLDocument]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentViewModeDidChangeNotification object:self userInfo:nil];
		}
		
		[self updateCount];
	}
}



- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
#if MD_DEBUG
	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *toolTip = @"";
	
	NSEvent *currentEvent = [NSApp currentEvent];
	
	NSUInteger modifierFlags = [currentEvent modifierFlags];
	
	HKArchiveFileType archiveFileType = [file archiveFileType];
	
	
	if (modifierFlags & NSCommandKeyMask) {
		
#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] NSCommandKeyMask", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		if (tag == statusImageViewTag1) {
			
			switch (archiveFileType) {
				case HKArchiveFileBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileGCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
				case HKArchiveFilePAKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Package file", @"")];
					break;
				case HKArchiveFileVBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileWADType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Texture Package file", @"")];
					break;
				case HKArchiveFileXZPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Xbox Package file", @"")];
					break;
				case HKArchiveFileNCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Steam Non-Cache file", @"")];
					break;
				case HKArchiveFileVPKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Source Valve Package file", @"")];
					break;
					
				default:
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that the items in this window are inside a %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
			}
			
		} else if (tag == statusImageViewTag2) {
			
			switch (archiveFileType) {
				case HKArchiveFileBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileGCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
				case HKArchiveFilePAKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Package file", @"")];
					break;
				case HKArchiveFileVBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileWADType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Texture Package file", @"")];
					break;
				case HKArchiveFileXZPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Xbox Package file", @"")];
					break;
				case HKArchiveFileNCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Steam Non-Cache file", @"")];
					break;
				case HKArchiveFileVPKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Source Valve Package file", @"")];
					break;
					
				default:
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Indicates that you cannot add or change the contents of this %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
			}
			
		}
	} else {
		if (tag == statusImageViewTag1) {
			
			switch (archiveFileType) {
				case HKArchiveFileBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileGCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
				case HKArchiveFilePAKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Package file", @"")];
					break;
				case HKArchiveFileVBSPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Level", @"")];
					break;
				case HKArchiveFileWADType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Texture Package file", @"")];
					break;
				case HKArchiveFileXZPType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Xbox Package file", @"")];
					break;
				case HKArchiveFileNCFType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Steam Non-Cache file", @"")];
					break;
				case HKArchiveFileVPKType :
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Source Valve Package file", @"")];
					break;
					
				default:
					toolTip = [NSString stringWithFormat:NSLocalizedString(@"Inside %@", @""), NSLocalizedString(@"Steam Cache file", @"")];
					break;
			}
		
		} else if (tag == statusImageViewTag2) {
			
			toolTip = NSLocalizedString(@"No Changes", @"");
		}
	}
	
	return toolTip;
}


// we define this method and intercept it so that our validateMenuItem: can properly update the menu item as long as a document is open.
- (IBAction)toggleShowQuickLook:(id)sender {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return [(MDAppController *)[NSApp delegate] toggleShowQuickLook:sender];
}



- (IBAction)toggleShowPathBar:(id)sender {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[[self class] setShouldShowPathBar:![[self class] shouldShowPathBar]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[[self class] shouldShowPathBar]] forKey:MDHLDocumentShouldShowPathBarKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:MDHLDocumentShouldShowPathBarDidChangeNotification object:self userInfo:nil];
}


#pragma mark - <NSMenuDelegate>

- (void)menuNeedsUpdate:(NSMenu *)menu {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSInteger selectedCount = -1;
	
	if (viewMode == MDHLDocumentListViewMode) {
		selectedCount = [outlineView numberOfSelectedRows];
	} else if (viewMode == MDHLDocumentColumnViewMode) {
		NSInteger selectedColumn = [browser selectedColumn];
		if (selectedColumn == -1) {
			selectedCount = 0;
		} else {
			NSIndexSet *indexSet = [browser selectedRowIndexesInColumn:selectedColumn];
			if (indexSet) {
				selectedCount = [indexSet count];
			}
			
		}
	}
	
	if (menu == [actionButton menu]) {
		
		if (selectedCount == 0) {
			[actionButton setItemArray:[NSArray arrayWithObjects:
										actionButtonActionImageItem,
										actionButtonShowInspectorMenuItem,
										[NSMenuItem separatorItem],
										actionButtonShowViewOptionsMenuItem, nil]];
		} else if (selectedCount >= 1) {
				
			[actionButton setItemArray:[NSArray arrayWithObjects:
										actionButtonActionImageItem,
										actionButtonShowInspectorMenuItem,
										actionButtonShowQuickLookMenuItem,
										[NSMenuItem separatorItem],
										actionButtonShowViewOptionsMenuItem, nil]];
			
		}
		
		
		[actionButtonShowViewOptionsMenuItem setTitle:([[self class] shouldShowViewOptions] ? NSLocalizedString(@"Hide View Options",@"") : NSLocalizedString(@"Show View Options", @""))];
		
		[actionButtonShowInspectorMenuItem setTitle:([[self class] shouldShowInspector] ? NSLocalizedString(@"Hide Inspector", @"") : NSLocalizedString(@"Show Inspector", @""))];
		
		
	} else if (menu == outlineViewMenu) {
		
		if (selectedCount == 0) {
			[outlineViewMenu setItemArray:[NSArray arrayWithObjects:
										   outlineViewMenuShowInspectorMenuItem,
										   [NSMenuItem separatorItem],
										   outlineViewMenuShowViewOptionsMenuItem, nil]];
		} else if (selectedCount >= 1) {
			[outlineViewMenu setItemArray:[NSArray arrayWithObjects:
										   outlineViewMenuShowInspectorMenuItem,
										   outlineViewMenuShowQuickLookMenuItem,
										   [NSMenuItem separatorItem],
										   outlineViewMenuShowViewOptionsMenuItem, nil]];
		}
		
		
		[outlineViewMenuShowViewOptionsMenuItem setTitle:([[self class] shouldShowViewOptions] ? NSLocalizedString(@"Hide View Options", @"") : NSLocalizedString(@"Show View Options", @""))];
		
		[outlineViewMenuShowInspectorMenuItem setTitle:([[self class] shouldShowInspector] ? NSLocalizedString(@"Hide Inspector", @"") : NSLocalizedString(@"Show Inspector", @""))];
		
		
	} else if (menu == browserMenu) {
		
		if (selectedCount == 0) {
			[browserMenu setItemArray:[NSArray arrayWithObjects:
									   browserMenuShowInspectorMenuItem,
									   [NSMenuItem separatorItem],
									   browserMenuShowViewOptionsMenuItem, nil]];
		} else if (selectedCount >= 1) {
			[browserMenu setItemArray:[NSArray arrayWithObjects:
									   browserMenuShowInspectorMenuItem,
									   browserMenuShowQuickLookMenuItem,
									   [NSMenuItem separatorItem],
									   browserMenuShowViewOptionsMenuItem, nil]];
		}
		
		[browserMenuShowViewOptionsMenuItem setTitle:([[self class] shouldShowViewOptions] ? NSLocalizedString(@"Hide View Options", @"") : NSLocalizedString(@"Show View Options", @""))];
		
		[browserMenuShowInspectorMenuItem setTitle:([[self class] shouldShowInspector] ? NSLocalizedString(@"Hide Inspector", @"") : NSLocalizedString(@"Show Inspector", @""))];
		
	} else if (menu == pathControlMenu) {

#if MD_DEBUG
		NSLog(@" \"%@\" [%@ %@] ****** menu == pathControlMenu *******", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
	}
}



- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@] menuItem == %@, action == %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem, NSStringFromSelector([menuItem action]));
#endif
	
	SEL action = [menuItem action];
	NSInteger tag = [menuItem tag];
	
	if (action == @selector(switchViewMode:)) {
		if (isSearching) {
			if (tag == MDHLDocumentListViewMode) {
				[menuItem setState:NSOnState];
				return YES;
			} else if (tag == MDHLDocumentColumnViewMode) {
				[menuItem setState:NSOffState];
				return NO;
			}
		} else {
			if (tag == MDHLDocumentListViewMode) {
				[menuItem setState:(viewMode == MDHLDocumentListViewMode ?  NSOnState : NSOffState)];
			} else if (tag == MDHLDocumentColumnViewMode) {
				[menuItem setState:(viewMode == MDHLDocumentColumnViewMode ?  NSOnState : NSOffState)];
			}
		}
		
	} else if (action == @selector(toggleShowInspector:)) {
		return YES;
		
	} else if (action == @selector(toggleShowPathBar:)) {
		[menuItem setTitle:([[self class] shouldShowPathBar] ? NSLocalizedString(@"Hide Path Bar", @"") : NSLocalizedString(@"Show Path Bar", @""))];
		return YES;
		
	} else if (action == @selector(copy:)) {
		return NO;
	} else if (action == @selector(paste:)) {
		return NO;
	} else if (action == @selector(toggleShowViewOptions:)) {
		return YES;
		
	} else if (action == @selector(toggleShowQuickLook:)) {
		if ([[self class] shouldShowQuickLook]) {
			[menuItem setTitle:NSLocalizedString(@"Close Quick Look", @"")];
			return YES;
		} else {
			NSInteger numberOfSelectedRows = -1;
			NSInteger selectedColumn = -1;
			
			if (viewMode == MDHLDocumentListViewMode) {
				numberOfSelectedRows = [outlineView numberOfSelectedRows];
			} else if (viewMode == MDHLDocumentColumnViewMode) {
				selectedColumn = [browser selectedColumn];
				if (selectedColumn == -1) {
					numberOfSelectedRows = 0;
				} else {
					NSIndexSet *indexSet = [browser selectedRowIndexesInColumn:selectedColumn];
					if (indexSet) {
						numberOfSelectedRows = [indexSet count];
					}
				}
			}
			
			if (numberOfSelectedRows == 0) {
				[menuItem setTitle:NSLocalizedString(@"Quick Look", @"")];
				return YES;
			} else if (numberOfSelectedRows == 1) {
				HKItem *selectedItem = nil;
				
				if (viewMode == MDHLDocumentListViewMode) {
					
					selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
					
				} else if (viewMode == MDHLDocumentColumnViewMode) {

					selectedItem = [browser itemAtRow:[[browser selectedRowIndexesInColumn:selectedColumn] firstIndex] inColumn:selectedColumn];
				}
				
				if (selectedItem) {
					[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Quick Look \"%@\"", @""), [selectedItem name]]];
				}
				return YES;
			} else if (numberOfSelectedRows > 1) {
				[menuItem setTitle:[NSString stringWithFormat:NSLocalizedString(@"Quick Look %lu Items", @""), (unsigned long)numberOfSelectedRows]];
				return YES;
			}
		}
		
	} else if (action == @selector(saveDocument:) ||
			   action == @selector(saveDocumentAs:) ||
			   action == @selector(saveDocumentTo:) ||
			   action == @selector(duplicateDocument:) ||
			   action == @selector(renameDocument:) ||
			   action == @selector(moveDocument:) ||
			   action == @selector(revertDocumentToSaved:)
			   
			   ) {
		return NO;
		
	} else if (action == @selector(revealInFinder:)) {
		if ([pathControl clickedPathComponentCell]) {
			return YES;
		}
		return NO;
		
	} else if (action == @selector(revealParentInFinder:)) {
		if ([pathControl clickedPathComponentCell]) {
			return YES;
		}
		return NO;
	} else if (action == @selector(findAdvanced:)) {
		return NO;
	}
	
	return YES;
}


#pragma mark END <NSMenuDelegate>
#pragma mark -


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
#if MD_DEBUG
//	NSLog(@" \"%@\" [%@ %@] %@", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd), theItem);
#endif
	
	SEL action = [theItem action];
	
	if (action == @selector(toggleShowInspector:)) {
		return [hlWindow isMainWindow];
	}
	return [hlWindow isMainWindow];
}


- (NSString *)description {
#if MD_DEBUG
	static const NSString * const MDHLDocumentViewModeDescriptions[] = {
		@"MDHLDocumentNoViewMode",
		@"MDHLDocumentListViewMode",
		@"MDHLDocumentColumnViewMode",
	};
	
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@ '%@'", [super description], [self displayName]];
	[description appendFormat:@", %@", MDHLDocumentViewModeDescriptions[viewMode]];
	return description;
	
#else
	return [NSString stringWithFormat:@"%@ '%@'", [super description], [self displayName]];
#endif
	
}



@end

