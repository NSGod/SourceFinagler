//
//  TKOpenGLRenderer.h
//  Texture Kit
//
//  Created by Mark Douma on 12/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLBase.h>
#import <TextureKit/TKMath.h>


@class TKModel;
@class TKOpenGLView;


@interface TKOpenGLRenderer : NSObject {
	
	TKOpenGLView			*openGLView;	// non-retained
	
	NSSize					size;
	NSLock					*sizeLock;
	
	NSArray					*objects;
	
	NSLock					*hasRenderedLock;
	
//	NSLock					*havePreRenderedLock;
	
	TKVector3				cameraPosition;
	TKVector3				cameraRotation;
	float					zoomFactor;
	float					pitch;
	
	GLuint					defaultFrameBufferObjectName;
	
	BOOL					useVertexBufferObjects;
	
//	BOOL					hasPreRendered;
	BOOL					hasRendered;
	
}

- (id)initWithView:(TKOpenGLView *)anOpenGLView defaultFrameBufferObjectName:(GLuint)defaultFBOName;

//- (void)preRender;

- (void)render;



@property (assign) TKOpenGLView *openGLView;

@property (retain) NSArray *objects;

@property (assign) NSSize size;

@property (readonly, assign) BOOL hasRendered;


@property (assign) TKVector3 cameraPosition;
@property (assign) TKVector3 cameraRotation;

@property (nonatomic, assign) float pitch;
@property (nonatomic, assign) float zoomFactor;


@end



//- (void)resizeWithWidth:(GLuint)width height:(GLuint)height;

//@property (nonatomic, assign) TKVector3 cameraPosition;
//@property (nonatomic, assign) TKVector3 cameraRotation;


//@property (nonatomic, retain) NSArray *objects;



//@property (nonatomic, retain) TKModel *characterModel;


//@property (readonly, nonatomic, assign) BOOL hasRendered;




//#if RENDER_REFLECTION
//TKModel			*quadModel;
//
//GLuint			reflectTexName;
//GLuint			reflectFBOName;
//GLuint			reflectWidth;
//GLuint			reflectHeight;
//
//GLint			reflectModelViewUniformIdx;
//GLint			reflectProjectionUniformIdx;
//GLint			reflectNormalMatrixUniformIdx;
//
//#endif

//// Toggle this to disable the rendering the reflection
//// and setup of the GLSL progam, model and FBO used for
//// the reflection.
//#define RENDER_REFLECTION 0

//	TKModel					*characterModel;
//
//	GLint					characterModelViewProjectionUniformIndex;

//	GLfloat					characterAngle;




//	BOOL					hasRendered;

