//
//  TKModelDocument.h
//  Source Finagler
//
//  Created by Mark Douma on 12/2/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class SCNView;
@class SCNScene;


@interface TKModelDocument : NSDocument <NSOutlineViewDataSource> {
	IBOutlet NSWindow						*modelWindow;
	IBOutlet SCNView						*sceneView;
	
	IBOutlet NSOutlineView					*entitiesOutlineView;
	
	IBOutlet NSOutlineView					*sceneGraphOutlineView;
	
	
	IBOutlet NSSegmentedControl				*inspectorSegmentedControl;
	
	IBOutlet NSBox							*inspectorBox;
	
	IBOutlet NSView							*materialPropertiesView;
	
	IBOutlet NSView							*nodeInspetorView;
	
	
	
	
	
	SCNScene								*scene;
	
}


@property (nonatomic, retain) SCNScene *scene;




@end
