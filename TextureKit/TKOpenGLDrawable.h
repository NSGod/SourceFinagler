//
//  TKOpenGLDrawable.h
//  Texture Kit
//
//  Created by Mark Douma on 12/15/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//


@protocol TKOpenGLDrawable <NSObject>

@required

- (void)prepareToDraw;
- (void)draw;

@end



