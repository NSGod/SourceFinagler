//
//  TKOpenGLPrivateInterfaces.h
//  Texture Kit
//
//  Created by Mark Douma on 12/25/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKOpenGLView.h>
#import <TextureKit/TKOpenGLRenderer.h>



@interface TKOpenGLView (TKDisplayLinkPrivate)

- (void)startDisplayLink;
- (void)stopDisplayLink;


@end


