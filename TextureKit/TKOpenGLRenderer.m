//
//  TKOpenGLRenderer.m
//  Texture Kit
//
//  Created by Mark Douma on 12/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLRenderer.h>
#import <TextureKit/TKOpenGLView.h>
#import <TextureKit/TKMath.h>
#import <TextureKit/TKModel.h>
#import <TextureKit/TKShaderProgram.h>
#import <TextureKit/TKTexture.h>
#import <TextureKit/TKVTFTexture.h>
#import <TextureKit/TKDDSTexture.h>
#import <TextureKit/TKValueAdditions.h>
#import "TKOpenGLPrivateInterfaces.h"



#define TK_DEBUG 1



// Toggle this to disable vertex buffer objects
// (i.e. use client-side vertex array objects)
#define USE_VERTEX_BUFFER_OBJECTS 1



@implementation TKOpenGLRenderer

@synthesize openGLView;

@dynamic size;

@synthesize objects;

@synthesize hasRendered;


@synthesize pitch;
@synthesize zoomFactor;
@synthesize cameraPosition;
@synthesize cameraRotation;



- (id)initWithView:(TKOpenGLView *)anOpenGLView defaultFrameBufferObjectName:(GLuint)defaultFBOName {
	if ((self = [super init])) {
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
		
		sizeLock = [[NSLock alloc] init];
		hasRenderedLock = [[NSLock alloc] init];
		
		
//		havePreRenderedLock = [[NSLock alloc] init];
		
		[sizeLock setName:@"sizeLock"];
		[hasRenderedLock setName:@"hasRenderedLock"];
//		[havePreRenderedLock setName:@"havePreRenderedLock"];
		
		
//		objects = [[NSMutableArray alloc] init];
		
		
		////////////////////////////////////////////////////
		// Build all of our and setup initial state here  //
		// Don't wait until our real time run loop begins //
		////////////////////////////////////////////////////
		
		defaultFrameBufferObjectName = defaultFBOName;
		
		openGLView = anOpenGLView;
		
//		size = NSMakeSize(100.0, 100.0);
		
		size = [openGLView bounds].size;

//		viewWidth = 100;
//		viewHeight = 100;

//		characterAngle = 0;

		useVertexBufferObjects = USE_VERTEX_BUFFER_OBJECTS;
		
		self.cameraPosition = TKVector3Make(0.0f, 5.0f, 20.0f);
		
		

		//////////////////////////////
		// Load our character model //
		//////////////////////////////

//		characterModel = [[TKModel alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"]];
//		
//		NSLog(@"characterModel == %@", characterModel);
//		
//		////////////////////////////////////
//		// Load texture for our character //
//		////////////////////////////////////
//		
//		characterModel.texture = [TKTexture textureNamed:@"demon"];
//		
//		////////////////////////////////////////////////////
//		// Load and Setup shaders for character rendering //
//		////////////////////////////////////////////////////
//		
//		characterModel.shaderProgram = [TKShaderProgram shaderProgramNamed:@"character"];
//		
//		characterModel.shaderProgram.withNormals = NO;
//		characterModel.shaderProgram.withTexcoords = YES;
//		
//		characterModelViewProjectionUniformIndex = glGetUniformLocation(characterModel.shaderProgram.name, "modelViewProjectionMatrix");
//
//		if (characterModelViewProjectionUniformIndex < 0) {
//			NSLog(@"No modelViewProjectionMatrix in character shader");
//		}

		////////////////////////////////////////////////
		// Set up OpenGL state that will never change //
		////////////////////////////////////////////////

		// Depth test will always be enabled
		glEnable(GL_DEPTH_TEST);

		// We will always cull back faces for better performance
		glEnable(GL_CULL_FACE);

		// Always use this clear color
		glClearColor(0.5f, 0.4f, 0.5f, 1.0f);

		// Draw our scene once without presenting the rendered image.
		//   This is done in order to pre-warm OpenGL
		// We don't need to present the buffer since we don't actually want the
		//   user to see this, we're only drawing as a pre-warm stage
//		[self render];

		// Reset the characterAngle which is incremented in render
//		characterAngle = 0;

		// Check for errors to make sure all of our setup went ok
		TKGetGLError();
	}
	return self;
}


- (void)dealloc {
//	[characterModel release];
	[sizeLock release];
	[hasRenderedLock release];
//	[havePreRenderedLock release];
	[objects release];
	[super dealloc];
}


- (NSSize)size {
	NSSize rSize = NSZeroSize;
	[sizeLock lock];
	rSize = size;
	[sizeLock unlock];
	return rSize;
}


- (void)setSize:(NSSize)aSize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[sizeLock lock];
	size = aSize;
	glViewport(0, 0, size.width, size.height);
	[sizeLock unlock];
//	if (hasRendered) [openGLView setNeedsDisplay:YES];
}


//- (NSArray *)objects {
//	return objects;
//}
//
//
//- (void)setObjects:(NSArray *)anObjects {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[anObjects retain];
//	[objects release];
//	objects = anObjects;
//	
////	if (hasRendered) [openGLView setNeedsDisplay:YES];
//}


//- (void)preRender {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	[havePreRenderedLock lock];
//	hasPreRendered = YES;
//	[havePreRenderedLock unlock];
//}



- (void)render {
#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	BOOL lHasRendered = NO;
	
	[hasRenderedLock lock];
	lHasRendered = hasRendered;
	[hasRenderedLock unlock];
	
	if (lHasRendered == NO) {
#if TK_DEBUG
		NSLog(@"[%@ %@] haven't rendered before; beginning...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		NSOpenGLContext *openGLContext = [[[openGLView openGLContext] retain] autorelease];
		
		[openGLContext makeCurrentContext];
				
		
		CGLLockContext([openGLContext CGLContextObj]);
		
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		
		TKMatrix4 modelviewMatrix = TKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
														0.0f, 0.0f, 0.0f,
														0.0, 1.0, 0.0);
		
		@synchronized(objects) {
			
			for (TKModel *model in objects) {
				
				glUseProgram(model.shaderProgram.name);
				
				model.modelviewMatrix = TKMatrix4Multiply(model.modelviewMatrix, modelviewMatrix);
				
				[model.shaderProgram setValue:[NSValue valueWithMatrix4:model.modelviewMatrix] forUniformKey:@"modelViewProjectionMatrix"];
				
				glBindTexture(GL_TEXTURE_2D, model.texture.name);
				
				glBindVertexArray(model.name);
				
				glCullFace(GL_BACK);
				
				if (useVertexBufferObjects) {
					glDrawElements([model primType], [model numElements], [model elementType], 0);
				} else {
					glDrawElements([model primType], [model numElements], [model elementType], [model elements]);
					
				}
				
			}
			
		}
		
		
		CGLUnlockContext([openGLContext CGLContextObj]);
		
		[hasRenderedLock lock];
		hasRendered = YES;
		[hasRenderedLock unlock];
		
		[openGLView startDisplayLink];
		
		return;
		
	}
	
	
	if (lHasRendered) {
		
#if TK_DEBUG
		NSLog(@"[%@ %@] rendering...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
		
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		
		TKMatrix4 modelviewMatrix = TKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
														0.0f, 0.0f, 0.0f,
														0.0, 1.0, 0.0);
		
		@synchronized(objects) {
			
			for (TKModel *model in objects) {
				
				glUseProgram(model.shaderProgram.name);
				
				model.modelviewMatrix = TKMatrix4Multiply(model.modelviewMatrix, modelviewMatrix);
				
				[model.shaderProgram setValue:[NSValue valueWithMatrix4:model.modelviewMatrix] forUniformKey:@"modelViewProjectionMatrix"];
				
				glBindTexture(GL_TEXTURE_2D, model.texture.name);
				
				glBindVertexArray(model.name);
				
				glCullFace(GL_BACK);
				
				if (useVertexBufferObjects) {
					glDrawElements([model primType], [model numElements], [model elementType], 0);
				} else {
					glDrawElements([model primType], [model numElements], [model elementType], [model elements]);
					
				}
			}
			
		}
		
	}
	
}



- (void)render0 {
	// Set up the modelview and projection matricies

//	modelViewMatrix4;
//	projectionMatrix4;
//	modelViewProjectionMatrix4;
	
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	// Use the program for rendering our character
//	glUseProgram(characterModel.shaderProgram.name);
	
	// Calculate the projection matrix
//	TKMatrix4 projectionMatrix = TKMatrix4MakePerspective(TKMathDegreesToRadians(90), (float)size.width/(float)size.height, 5.0, 10000.0);
	
	// Calculate the modelview matrix to render our character
	//  at the proper position and rotation
	
	TKMatrix4 modelViewMatrix = TKMatrix4MakeTranslation(0.0f, 150.0f, -450.0f);
	
	modelViewMatrix = TKMatrix4RotateX(modelViewMatrix, TKMathRadiansToDegrees(90.0f));
	
	
//	TKMatrixRotateXApply(modelViewMatrix, -90.0f);
//	TKMatrixRotateApply(modelView, characterAngle, 0.7, 0.3, 1);

	// Multiply the modelview and projection matrix and set it in the shader
//	TKMatrix4 modelViewProjectionMatrix = TKMatrix4Multiply(projectionMatrix, modelViewMatrix);

	// Have our shader use the modelview projection matrix
	// that we calculated above
	
//	glUniformMatrix4fv(characterModelViewProjectionUniformIndex, 1, GL_FALSE, modelViewProjectionMatrix.m);
	
	
	
	// Bind the texture to be used
//	glBindTexture(GL_TEXTURE_2D, characterModel.texture.name);
	
	// Bind our vertex array object
//	glBindVertexArray(characterModel.name);

	// Cull back faces now that we no longer render
	// with an inverted matrix
	glCullFace(GL_BACK);
	
	
	// Draw our character
	if (useVertexBufferObjects) {
//		glDrawElements(GL_TRIANGLES, [characterModel numElements], [characterModel elementType], 0);
	} else {
//		glDrawElements(GL_TRIANGLES, [characterModel numElements], [characterModel elementType], [characterModel elements]);
	}


	// Update the angle so our character keeps spinning
//	characterAngle++;
	
	
//	if (hasRendered == NO) hasRendered = YES;
}



- (void)deleteFrameBufferObjectAttachment:(GLenum)attachment {
	GLint param;
	GLuint objName;

	glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE, &param);

	if (GL_RENDERBUFFER == param) {
		glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &param);

		objName = ((GLuint *)(&param))[0];
		glDeleteRenderbuffers(1, &objName);
		
	} else if (GL_TEXTURE == param) {

		glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &param);

		objName = ((GLuint *)(&param))[0];
		glDeleteTextures(1, &objName);
	}
}

- (void)destroyFrameBufferObjectWithName:(GLuint)fboName {
	if (0 == fboName) {
		return;
	}
	glBindFramebuffer(GL_FRAMEBUFFER, fboName);


	GLint maxColorAttachments = 1;


	// OpenGL ES on iOS 4 has only 1 attachment.
	// There are many possible attachments on OpenGL
	// on MacOSX so we query how many below
#if !TARGET_OS_IPHONE
	glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &maxColorAttachments);
#endif

	GLint colorAttachment;
	// For every color buffer attached
	for (colorAttachment = 0; colorAttachment < maxColorAttachments; colorAttachment++) {
		// Delete the attachment
		[self deleteFrameBufferObjectAttachment:(GL_COLOR_ATTACHMENT0 + colorAttachment)];
	}

	// Delete any depth or stencil buffer attached
	[self deleteFrameBufferObjectAttachment:GL_DEPTH_ATTACHMENT];

	[self deleteFrameBufferObjectAttachment:GL_STENCIL_ATTACHMENT];

	glDeleteFramebuffers(1, &fboName);
}



- (GLuint)frameBufferObjectNameWithWidth:(GLuint)width height:(GLuint)height {
	GLuint fboName;

	GLuint colorTexture;

	// Create a texture object to apply to model
	glGenTextures(1, &colorTexture);
	glBindTexture(GL_TEXTURE_2D, colorTexture);

	// Set up filter and wrap modes for this texture object
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
#if TARGET_OS_IPHONE
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
#else
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
#endif

	// Allocate a texture image with which we can render to
	// Pass NULL for the data parameter since we don't need to load image data.
	//     We will be generating the image by rendering to this texture
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

	GLuint depthRenderbuffer;
	glGenRenderbuffers(1, &depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);

	glGenFramebuffers(1, &fboName);
	glBindFramebuffer(GL_FRAMEBUFFER, fboName);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture, 0);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		[self destroyFrameBufferObjectWithName:fboName];
		return 0;
	}
	TKGetGLError();

	return fboName;
}



@end





//
//#if RENDER_REFLECTION
//
//	// Bind our refletion FBO and render our scene
//
//	glBindFramebuffer(GL_FRAMEBUFFER, reflectFBOName);
//
//
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//	glViewport(0, 0, reflectWidth, reflectHeight);
//
//	TKMatrixLoadPerspective(projection, 90, (float)reflectWidth/(float)reflectHeight, 5.0, 10000);
//
//	TKMatrixLoadIdentity(modelView);
//
//	// Invert Y so that everything is rendered up-side-down
//	// as it should with a reflection
//
//	TKMatrixScaleApply(modelView, 1, -1, 1);
//	TKMatrixTranslateApply(modelView, 0, 300, -800);
//	TKMatrixRotateXApply(modelView, -90.0f);
//	TKMatrixRotateApply(modelView, characterAngle, 0.7, 0.3, 1);
//
//	TKMatrixMultiply(mvp, projection, modelView);
//
//	// Use the program that we previously created
//	glUseProgram(characterModel.shader.name);
//
//	// Set the modelview projection matrix that we calculated above
//	// in our vertex shader
//	glUniformMatrix4fv(characterModelViewProjectionUniformIndex, 1, GL_FALSE, mvp);
//
//	// Bind our vertex array object
//	glBindVertexArray(characterModel.vertexArrayObjectName);
//
//	// Bind the texture to be used
//	glBindTexture(GL_TEXTURE_2D, characterModel.texture.name);
//
//	// Cull front faces now that everything is flipped
//	// with our inverted reflection transformation matrix
//	glCullFace(GL_FRONT);
//
//	// Draw our object
//	if (useVertexBufferObjects) {
//		glDrawElements(GL_TRIANGLES, characterModel->numElements, characterModel->elementType, 0);
//	} else {
//		glDrawElements(GL_TRIANGLES, characterModel->numElements, characterModel->elementType, characterModel->elements);
//	}
//	
//	
//	// Bind our default FBO to render to the screen
//	glBindFramebuffer(GL_FRAMEBUFFER, defaultFrameBufferObjectName);
//
//	glViewport(0, 0, viewWidth, viewHeight);
//
//#endif // RENDER_REFLECTION


//#if RENDER_REFLECTION
//
//		reflectWidth = 512;
//		reflectHeight = 512;
//
//		////////////////////////////////////////////////
//		// Load a model for a quad for the reflection //
//		////////////////////////////////////////////////
//		
//		quadModel = [[TKModel quadModel] retain];
//		
//		/////////////////////////////////////////////////////
//		// Create texture and FBO for reflection rendering //
//		/////////////////////////////////////////////////////
//
//		reflectFBOName = [self frameBufferObjectNameWithWidth:reflectWidth height:reflectHeight];
//
//		// Get the texture we created in buildReflectFBO by binding the
//		// reflection FBO and getting the buffer attached to color 0
//		glBindFramebuffer(GL_FRAMEBUFFER, reflectFBOName);
//
//		GLint iReflectTexName;
//
//		glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME, &iReflectTexName);
//
//		reflectTexName = ((GLuint *)(&iReflectTexName))[0];
//
//		/////////////////////////////////////////////////////
//		// Load and setup shaders for reflection rendering //
//		/////////////////////////////////////////////////////
//		
//		quadModel.shader = [TKShader shaderNamed:@"reflect"];
//		quadModel.shader.withNormals = YES;
//		quadModel.shader.withTexcoords = NO;
//		
//		reflectModelViewUniformIdx = glGetUniformLocation(quadModel.shader.name, "modelViewMatrix");
//
//		if (reflectModelViewUniformIdx < 0) {
//			NSLog(@"No modelViewMatrix in reflection shader");
//		}
//		reflectProjectionUniformIdx = glGetUniformLocation(quadModel.shader.name, "modelViewProjectionMatrix");
//
//		if (reflectProjectionUniformIdx < 0) {
//			NSLog(@"No modelViewProjectionMatrix in reflection shader");
//		}
//		reflectNormalMatrixUniformIdx = glGetUniformLocation(quadModel.shader.name, "normalMatrix");
//
//		if (reflectNormalMatrixUniformIdx < 0) {
//			NSLog(@"No normalMatrix in reflection shader");
//		}
//		
//#endif // RENDER_REFLECTION


//#if RENDER_REFLECTION
//	[self destroyFrameBufferObjectWithName:reflectFBOName];
//
//	[quadModel release];
//	
//#endif // RENDER_REFLECTION


//#if RENDER_REFLECTION
//
//	// Use our shader for reflections
//	glUseProgram(quadModel.shader.name);
//	
//	TKMatrixLoadTranslate(modelView, 0, -50, -250);
//
//	// Multiply the modelview and projection matrix and set it in the shader
//	TKMatrixMultiply(mvp, projection, modelView);
//
//	// Set the modelview matrix that we calculated above
//	// in our vertex shader
//	glUniformMatrix4fv(reflectModelViewUniformIdx, 1, GL_FALSE, modelView);
//
//	// Set the projection matrix that we calculated above
//	// in our vertex shader
//	glUniformMatrix4fv(reflectProjectionUniformIdx, 1, GL_FALSE, mvp);
//
//	float normalMatrix[9];
//
//	// Calculate the normal matrix so that we can
//	// generate texture coordinates in our fragment shader
//
//	// The normal matrix needs to be the inverse transpose of the
//	//   top left 3x3 portion of the modelview matrix
//	// We don't need to calculate the inverse transpose matrix
//	//   here because this will always be an orthonormal matrix
//	//   thus the the inverse tranpose is the same thing
//	TKMatrix3x3FromTopLeftOf4x4(normalMatrix, modelView);
//
//	// Set the normal matrix for our shader to use
//	glUniformMatrix3fv(reflectNormalMatrixUniformIdx, 1, GL_FALSE, normalMatrix);
//
//	// Bind the texture we rendered-to above (i.e. the reflection texture)
//	glBindTexture(GL_TEXTURE_2D, reflectTexName);
//
//#if !ESSENTIAL_GL_PRACTICES_IPHONE_OS
//	// Generate mipmaps from the rendered-to base level
//	//   Mipmaps reduce shimmering pixels due to better filtering
//	// This call is not accelarated on iOS 4 so do not use
//	//   mipmaps here
//	glGenerateMipmap(GL_TEXTURE_2D);
//#endif
//	
//	// Bind our vertex array object
//	glBindVertexArray(quadModel.vertexArrayObjectName);
//
//	// Draw our refection plane
//	if (useVertexBufferObjects) {
//		glDrawElements(GL_TRIANGLES, quadModel->numElements, quadModel->elementType, 0);
//	} else {
//		glDrawElements(GL_TRIANGLES, quadModel->numElements, quadModel->elementType, quadModel->elements);
//	}
//
//#endif // RENDER_REFLECTION


//- (void)render {
//	// Set up the modelview and projection matricies
//	GLfloat modelViewMatrix[16];
//	GLfloat projectionMatrix[16];
//	GLfloat modelViewProjectionMatrix[16];
//	
//	TKMatrix4 modelViewMatrix4;
//	TKMatrix4 projectionMatrix4;
//	TKMatrix4 modelViewProjectionMatrix4;
//	
//	
//	
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//	
//	// Use the program for rendering our character
//	glUseProgram(characterModel.shader.name);
//	
//	// Calculate the projection matrix
//	TKMatrixLoadPerspective(projectionMatrix, 90, (float)viewWidth/(float)viewHeight, 5.0, 10000.0);
//	
//	// Calculate the modelview matrix to render our character
//	//  at the proper position and rotation
//	TKMatrixLoadTranslate(modelViewMatrix, 0, 150, -450);
//	//	TKMatrixRotateXApply(modelViewMatrix, -90.0f);
//	//	TKMatrixRotateApply(modelView, characterAngle, 0.7, 0.3, 1);
//	
//	// Multiply the modelview and projection matrix and set it in the shader
//	TKMatrixMultiply(modelViewProjectionMatrix, projectionMatrix, modelViewMatrix);
//	
//	// Have our shader use the modelview projection matrix
//	// that we calculated above
//	glUniformMatrix4fv(characterModelViewProjectionUniformIndex, 1, GL_FALSE, modelViewProjectionMatrix);
//	
//	
//	// Bind the texture to be used
//	glBindTexture(GL_TEXTURE_2D, characterModel.texture.name);
//	
//	// Bind our vertex array object
//	glBindVertexArray(characterModel.vertexArrayObjectName);
//	
//	// Cull back faces now that we no longer render
//	// with an inverted matrix
//	glCullFace(GL_BACK);
//	
//	
//	// Draw our character
//	if (useVertexBufferObjects) {
//		glDrawElements(GL_TRIANGLES, characterModel->numElements, characterModel->elementType, 0);
//	} else {
//		glDrawElements(GL_TRIANGLES, characterModel->numElements, characterModel->elementType, characterModel->elements);
//	}
//	
//	
//	// Update the angle so our character keeps spinning
//	//	characterAngle++;
//}



//- (void)render {
//	// Set up the modelview and projection matricies
//	
//	//	modelViewMatrix4;
//	//	projectionMatrix4;
//	//	modelViewProjectionMatrix4;
//	
//	
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//	
//	// Use the program for rendering our character
//	glUseProgram(characterModel.shader.name);
//	
//	// Calculate the projection matrix
//	TKMatrix4 projectionMatrix = TKMatrix4MakePerspective(TKMathDegreesToRadians(90), (float)size.width/(float)size.height, 5.0, 10000.0);
//	
//	// Calculate the modelview matrix to render our character
//	//  at the proper position and rotation
//	
//	TKMatrix4 modelViewMatrix = TKMatrix4MakeTranslation(0.0f, 150.0f, -450.0f);
//	
//	modelViewMatrix = TKMatrix4RotateX(modelViewMatrix, TKMathRadiansToDegrees(90.0f));
//	
//	
//	//	TKMatrixRotateXApply(modelViewMatrix, -90.0f);
//	//	TKMatrixRotateApply(modelView, characterAngle, 0.7, 0.3, 1);
//	
//	// Multiply the modelview and projection matrix and set it in the shader
//	TKMatrix4 modelViewProjectionMatrix = TKMatrix4Multiply(projectionMatrix, modelViewMatrix);
//	
//	// Have our shader use the modelview projection matrix
//	// that we calculated above
//	
//	glUniformMatrix4fv(characterModelViewProjectionUniformIndex, 1, GL_FALSE, modelViewProjectionMatrix.m);
//	
//	
//	
//	// Bind the texture to be used
//	glBindTexture(GL_TEXTURE_2D, characterModel.texture.name);
//	
//	// Bind our vertex array object
//	glBindVertexArray(characterModel.vertexArrayObjectName);
//	
//	// Cull back faces now that we no longer render
//	// with an inverted matrix
//	glCullFace(GL_BACK);
//	
//	
//	// Draw our character
//	if (useVertexBufferObjects) {
//		glDrawElements(GL_TRIANGLES, [characterModel numElements], [characterModel elementType], 0);
//	} else {
//		glDrawElements(GL_TRIANGLES, [characterModel numElements], [characterModel elementType], [characterModel elements]);
//	}
//	
//	
//	// Update the angle so our character keeps spinning
//	//	characterAngle++;
//}




//- (TKVector3)cameraPosition {
//	return cameraPosition;
//}
//
//
//- (void)setCameraPosition:(TKVector3)aCameraPosition {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	cameraPosition = aCameraPosition;
//	
////	if (hasRendered) [openGLView setNeedsDisplay:YES];
//}
//
//
//- (TKVector3)cameraRotation {
//	return cameraRotation;
//}
//
//
//- (void)setCameraRotation:(TKVector3)aCameraRotation {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	cameraRotation = aCameraRotation;
//	
////	if (hasRendered) [openGLView setNeedsDisplay:YES];
//}


//- (void)resizeWithWidth:(GLuint)width height:(GLuint)height {
//	glViewport(0, 0, width, height);
//
//	viewWidth = width;
//	viewHeight = height;
//
//}



//@dynamic objects;


//@synthesize quadModel;
//@synthesize characterModel;

//@dynamic cameraPosition;
//
//@dynamic cameraRotation;

//@synthesize hasRendered;

//- (void)render {
//#if TK_DEBUG
////	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	BOOL lHavePreRendered = NO;
//	
//	[havePreRenderedLock lock];
//	lHavePreRendered = hasPreRendered;
//	[havePreRenderedLock unlock];
//	
//	if (lHavePreRendered == NO) {
//#if TK_DEBUG
//		NSLog(@"[%@ %@] haven't preRendered; ignoring...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//		return;
//		
//	}
//	
//	if (lHavePreRendered) {
//		
//#if TK_DEBUG
//		NSLog(@"[%@ %@] rendering...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//		
//		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//		
//		
//		TKMatrix4 modelviewMatrix = TKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
//														0.0f, 0.0f, 0.0f,
//														0.0, 1.0, 0.0);
//		
//		
//		
//		for (TKModel *model in objects) {
//			model.modelviewMatrix = TKMatrix4Multiply(model.modelviewMatrix, modelviewMatrix);
//			
//			[model prepareToDraw];
//			
//			[model draw];
//			
//			
//		}
//	}
//	
//}



//
//- (void)render {
//#if TK_DEBUG
////	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//
//BOOL lHavePreRendered = NO;
//
//[havePreRenderedLock lock];
//lHavePreRendered = hasPreRendered;
//[havePreRenderedLock unlock];
//
//if (lHavePreRendered == NO) {
//#if TK_DEBUG
//	NSLog(@"[%@ %@] haven't preRendered; ignoring...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	return;
//	
//}
//
//if (lHavePreRendered) {
//	
//#if TK_DEBUG
//	NSLog(@"[%@ %@] rendering...", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	
//	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//	
//	
//	TKMatrix4 modelviewMatrix = TKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
//													0.0f, 0.0f, 0.0f,
//													0.0, 1.0, 0.0);
//	
//	@synchronized(objects) {
//		
//		for (TKModel *model in objects) {
//			
//			glUseProgram(model.shaderProgram.name);
//			
//			model.modelviewMatrix = TKMatrix4Multiply(model.modelviewMatrix, modelviewMatrix);
//			
//			[model.shaderProgram setValue:[NSValue valueWithMatrix4:model.modelviewMatrix] forUniformKey:@"modelViewProjectionMatrix"];
//			
//			glBindTexture(GL_TEXTURE_2D, model.texture.name);
//			
//			glBindVertexArray(model.name);
//			
//			glCullFace(GL_BACK);
//			
//			if (useVertexBufferObjects) {
//				glDrawElements([model primType], [model numElements], [model elementType], 0);
//			} else {
//				glDrawElements([model primType], [model numElements], [model elementType], [model elements]);
//				
//			}
//			
//			
//			//				[model prepareToDraw];
//			//				
//			//				[model draw];
//			
//			
//		}
//		
//	}
//	
//}
//
//}
//
