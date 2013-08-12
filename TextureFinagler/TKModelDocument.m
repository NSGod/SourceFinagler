//
//  TKModelDocument.m
//  Source Finagler
//
//  Created by Mark Douma on 12/2/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import "TKModelDocument.h"
#import <TextureKit/TextureKit.h>
#import <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>

#import "TKMaterialPropertyViewController.h"




#define TK_DEBUG 1



@implementation TKModelDocument

@synthesize scene;


- (id)init {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
    if ((self = [super init])) {
		
        // Add your subclass-specific initialization here.
        // If an error occurs here, return nil.
    }
    return self;
}


- (id)initWithType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		
		scene = [[SCNScene scene] retain];
		
		// Add a camera to the scene
		SCNNode *cameraNode = [SCNNode node];
		cameraNode.camera = [SCNCamera camera];	
		cameraNode.position = SCNVector3Make(0, 0, 30);
		[scene.rootNode addChildNode:cameraNode];
		
		
		// Add a diffuse light to the scene
		SCNNode *diffuseLightNode = [SCNNode node];
//		self.diffuseLightNode = [SCNNode node];
		diffuseLightNode.light = [SCNLight light];
		diffuseLightNode.light.type = SCNLightTypeOmni;
		diffuseLightNode.position = SCNVector3Make(-30, 30, 50);
		[scene.rootNode addChildNode:diffuseLightNode];
		
		// Add an ambient light to the scene
		SCNNode *ambientLightNode = [SCNNode node];
//		self.ambientLightNode = [SCNNode node];
		ambientLightNode.light = [SCNLight light];
		ambientLightNode.light.type = SCNLightTypeAmbient;
		ambientLightNode.light.color = [NSColor colorWithDeviceWhite:0.1 alpha:1.0];
		[scene.rootNode addChildNode:ambientLightNode];
		
		
	}
	return self;
}




- (void)dealloc {
	[scene release];
	[super dealloc];
}




- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"TKModelDocument";
}


- (BOOL)readFromURL:(NSURL *)absURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	self.scene = [SCNScene sceneWithURL:absURL options:nil error:outError];
	
	return (scene != nil);
}


- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@] typeName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), typeName);
#endif
	
	BOOL success = NO;
	return success;
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
    [super windowControllerDidLoadNib:aController];
	
	sceneView.scene = self.scene;
	
#if TK_DEBUG
    NSLog(@"[%@ %@] scene == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), scene);
    NSLog(@"[%@ %@] scene.rootNode == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), scene.rootNode);
#endif
	
	
	
}


+ (BOOL)autosavesInPlace {
    return YES;
}





#pragma mark -
#pragma mark <NSOutlineViewDataSource>


- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outlineView == entitiesOutlineView) {
		
	} else if (outlineView == sceneGraphOutlineView) {
		if (item == nil) return scene.rootNode.childNodes.count;
		return [(SCNNode *)item childNodes].count;
		
	}
	return 0;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outlineView == entitiesOutlineView) {
		
	} else if (outlineView == sceneGraphOutlineView) {
		if (item == nil) return [scene.rootNode.childNodes objectAtIndex:index];
		return [[(SCNNode *)item childNodes] objectAtIndex:index];

	}
	return nil;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outlineView == entitiesOutlineView) {
		
		
		
	} else if (outlineView == sceneGraphOutlineView) {
		if (item == nil) return scene.rootNode.childNodes.count;
		return [(SCNNode *)item childNodes].count;
	}
	return NO;
}



#pragma mark END <NSOutlineViewDataSource>
#pragma mark -
#pragma mark <NSOutlineViewDelegate>



- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
#if TK_DEBUG
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if (outlineView == entitiesOutlineView) {
		
		
		
		
	} else if (outlineView == sceneGraphOutlineView) {
		NSTableCellView *view = [outlineView makeViewWithIdentifier:@"TKModelOutlineCellView" owner:self];
		
		SCNNode *node = (SCNNode *)item;
		
		view.textField.stringValue = (node.name ? node.name : @"<untitled>");
		
		if (node.light) {
			view.imageView.image = [NSImage imageNamed:@"entityLight"];
			
		} else if (node.camera) {
			view.imageView.image = [NSImage imageNamed:@"entityCamera"];
			
		} else if (node.geometry) {
			view.imageView.image = [NSImage imageNamed:@"entityGeometry"];
			
			
		} else {
			view.imageView.image = nil;
		}
		return view;
	}
	return nil;
}







#pragma mark END <NSOutlineViewDelegate>
#pragma mark -

@end




