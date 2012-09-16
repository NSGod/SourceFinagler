//
//  TKModel.h
//  Texture Kit
//
//  Created by Mark Douma on 11/27/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLBase.h>
#import <TextureKit/TKOpenGLDrawable.h>
#import <TextureKit/TKMath.h>
#import <TextureKit/TKOpenGLObject.h>

@class TKShaderProgram;
@class TKTexture;



@interface TKModel : TKOpenGLObject <TKOpenGLDrawable> {
	
//	GLuint					name;	vertexArrayObjectName
//	GLuint					vertexArrayObjectName;
	
	
	GLuint					numVertices;
	
	GLubyte					*positions;
	GLenum					positionType;
	GLuint					positionSize;
	GLsizei					positionArraySize;

	GLubyte					*texcoords;
	GLenum					texcoordType;
	GLuint					texcoordSize;
	GLsizei					texcoordArraySize;

	GLubyte					*normals;
	GLenum					normalType;
	GLuint					normalSize;
	GLsizei					normalArraySize;

	GLubyte					*elements;
	GLenum					elementType;
	GLuint					numElements;
	GLsizei					elementArraySize;

	GLenum					primType;
	
	
	TKMatrix4				modelviewMatrix;
	TKMatrix4				projectionMatrix;
	
	
	TKVector3				position;
	
	TKVector3				rotation;
	
	
	
	TKShaderProgram			*shaderProgram;
	
	TKTexture				*texture;
	
	
	BOOL					useVertexBufferObjects;
	
//	BOOL					vertexArrayObjectGenerated;
	
}

+ (id)quadModel;

+ (id)modelWithContentsOfFile:(NSString *)filePath;
+ (id)modelWithContentsOfURL:(NSURL *)URL;
+ (id)modelWithData:(NSData *)data;

- (id)initWithContentsOfFile:(NSString *)filePath;
- (id)initWithContentsOfURL:(NSURL *)URL;
- (id)initWithData:(NSData *)data;


@property (readonly, nonatomic, assign) GLuint numVertices;

@property (readonly, nonatomic, assign) GLubyte *positions;
@property (readonly, nonatomic, assign) GLenum positionType;
@property (readonly, nonatomic, assign) GLuint positionSize;
@property (readonly, nonatomic, assign) GLsizei positionArraySize;

@property (readonly, nonatomic, assign) GLubyte *texcoords;
@property (readonly, nonatomic, assign) GLenum texcoordType;
@property (readonly, nonatomic, assign) GLuint texcoordSize;
@property (readonly, nonatomic, assign) GLsizei texcoordArraySize;

@property (readonly, nonatomic, assign) GLubyte *normals;
@property (readonly, nonatomic, assign) GLenum normalType;
@property (readonly, nonatomic, assign) GLuint normalSize;
@property (readonly, nonatomic, assign) GLsizei normalArraySize;

@property (readonly, nonatomic, assign) GLubyte *elements;
@property (readonly, nonatomic, assign) GLenum elementType;
@property (readonly, nonatomic, assign) GLuint numElements;
@property (readonly, nonatomic, assign) GLsizei elementArraySize;

@property (readonly, nonatomic, assign) GLenum primType;


@property (nonatomic, assign) TKMatrix4 modelviewMatrix;
@property (nonatomic, assign) TKMatrix4 projectionMatrix;


@property (nonatomic, assign) TKVector3 position;

@property (nonatomic, assign) TKVector3 rotation;


//@property (readonly, nonatomic, assign) GLuint vertexArrayObjectName;

@property (retain) TKShaderProgram *shaderProgram;

@property (retain) TKTexture *texture;

//@property (nonatomic, retain) TKShaderProgram *shaderProgram;
//
//@property (nonatomic, retain) TKTexture *texture;

@property (nonatomic, assign) BOOL useVertexBufferObjects;


- (NSString *)stringRepresentation;


- (BOOL)parseModelData:(NSData *)data;

- (BOOL)haveEnoughBytesRemainingForObjectWithLength:(NSUInteger)neededLength
										totalLength:(NSUInteger)totalLength
									  currentOffset:(NSUInteger)currentOffset
										description:(NSString *)objectTypeDescription;


//- (void)generateVertexArrayObjectName;
- (void)destroyVertexArrayObjectWithName:(GLuint)vaoName;

@end

// Indicies to which we will set vertex array attributes
// See buildVAO and buildProgram
//enum {
//	TKPositionAttribIndex,
//	TKNormalAttribIndex,
//	TKTexcoordAttribIndex
//};



