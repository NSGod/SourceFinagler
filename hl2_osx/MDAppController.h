//
//  MDAppController.h
//  hl2_osx
//
//  Created by Mark Douma on 11/22/2012.
//  Copyright 2012 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MDAppController : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow				*window;
}

- (IBAction)quit:(id)sender;

@end



