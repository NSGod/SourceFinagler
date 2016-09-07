//
//  TKModel.m
//  Texture Kit
//
//  Created by Mark Douma on 11/27/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKModel.h>
#import <TextureKit/TKTexture.h>
#import <TextureKit/TKShaderProgram.h>
#import <TextureKit/TKValueAdditions.h>
#import "TKPrivateInterfaces.h"


#define TK_DEBUG 1

static NSString * const TKAppleOpenGLDemoIdentifier = @"AppleOpenGLDemoModelWWDC2010";

typedef struct {
	char			fileIdentifier[30];
	unsigned int	majorVersion;
	unsigned int	minorVersion;
} TKModelHeader;

typedef struct {
	unsigned int	attribHeaderSize;
	unsigned int	byteElementOffset;
	unsigned int	bytePositionOffset;
	unsigned int	byteTexcoordOffset;
	unsigned int	byteNormalOffset;
} TKModelTOC;


typedef struct {
	unsigned int	byteSize;
	GLenum			datatype;
	GLenum			primType; //If index data
	unsigned int	sizePerElement;
	unsigned int	numElements;
} TKModelAttributes;



@implementation TKModel

@synthesize numVertices;


@synthesize positions;
@synthesize positionType;
@synthesize positionSize;
@synthesize positionArraySize;
@synthesize texcoords;
@synthesize texcoordType;
@synthesize texcoordSize;
@synthesize texcoordArraySize;
@synthesize normals;
@synthesize normalType;
@synthesize normalSize;
@synthesize normalArraySize;
@synthesize elements;
@synthesize elementType;
@synthesize numElements;
@synthesize elementArraySize;

@synthesize primType;

//@synthesize vertexArrayObjectName;

@synthesize shaderProgram;

@synthesize texture;

@synthesize useVertexBufferObjects;

@synthesize position;
@synthesize rotation;

@synthesize modelviewMatrix;
@synthesize projectionMatrix;


+ (id)modelWithContentsOfFile:(NSString *)filePath {
	return [[[[self class] alloc] initWithContentsOfFile:filePath] autorelease];
}

+ (id)modelWithContentsOfURL:(NSURL *)URL {
	return [[[[self class] alloc] initWithContentsOfURL:URL] autorelease];
}


+ (id)modelWithData:(NSData *)data {
	return [[[[self class] alloc] initWithData:data] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)filePath {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
}


- (id)initWithContentsOfURL:(NSURL *)URL {
	return [self initWithData:[NSData dataWithContentsOfURL:URL]];
}


- (id)initWithData:(NSData *)data {
	NSParameterAssert(data != nil);
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		
		useVertexBufferObjects = YES;
		modelviewMatrix = TKMatrix4Identity;
		projectionMatrix = TKMatrix4Identity;
		
		if (![self parseModelData:data]) {
			
		}
		
//		[self generateVertexArrayObjectName];
	}
	return self;
}


- (id)initQuadModel {
	if ((self = [super init])) {
		useVertexBufferObjects = YES;
		
		GLfloat posArray[] = {
			-200.0f, 0.0f, -200.0f,
			 200.0f, 0.0f, -200.0f,
			 200.0f, 0.0f,	200.0f,
			-200.0f, 0.0f,	200.0f
		};
		
		GLfloat texcoordArray[] = {
			0.0f, 1.0f,
			1.0f, 1.0f,
			1.0f, 0.0f,
			0.0f, 0.0f
		};
		
		GLfloat normalArray[] = {
			0.0f, 0.0f, 1.0,
			0.0f, 0.0f, 1.0f,
			0.0f, 0.0f, 1.0f,
			0.0f, 0.0f, 1.0f,
		};
		
		GLushort elementArray[] = {
			0, 2, 1,
			0, 3, 2
		};
		
		positionType = GL_FLOAT;
		positionSize = 3;
		positionArraySize = sizeof(posArray);
		positions = (GLubyte *)malloc(positionArraySize);
		memcpy(positions, posArray, positionArraySize);
		
		texcoordType = GL_FLOAT;
		texcoordSize = 2;
		texcoordArraySize = sizeof(texcoordArray);
		texcoords = (GLubyte *)malloc(texcoordArraySize);
		memcpy(texcoords, texcoordArray, texcoordArraySize);
		
		normalType = GL_FLOAT;
		normalSize = 3;
		normalArraySize = sizeof(normalArray);
		normals = (GLubyte *)malloc(normalArraySize);
		memcpy(normals, normalArray, normalArraySize);
		
		
		elementArraySize = sizeof(elementArray);
		elements = (GLubyte *)malloc(elementArraySize);
		memcpy(elements, elementArray, elementArraySize);
		
		primType = GL_TRIANGLES;
		
		
		numElements = sizeof(elementArray) / sizeof(GLushort);
		elementType = GL_UNSIGNED_SHORT;
		numVertices = positionArraySize / (positionSize * sizeof(GLfloat));
		
		
		modelviewMatrix = TKMatrix4Identity;
		projectionMatrix = TKMatrix4Identity;

	}
	return self;
}

+ (id)quadModel {
	return [[[[self class] alloc] initQuadModel] autorelease];
}


- (void)dealloc {
	free(positions);
	free(texcoords);
	free(normals);
	free(elements);
	[self destroyVertexArrayObjectWithName:name];
	[shaderProgram release];
	[texture release];
	[super dealloc];
}


- (void)prepareToDraw {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[shaderProgram useProgram];
	
//	if (vertexArrayObjectGenerated == NO) {
//		[self generateVertexArrayObjectName];
//	}


//	if (vertexArrayObjectName == 0) {
//		[self generateVertexArrayObjectName];
//	}
	
//	[shaderProgram useProgram];
	
	[shaderProgram setValue:[NSValue valueWithMatrix4:modelviewMatrix] forUniformKey:@"modelViewProjectionMatrix"];

	[texture bind];

	glBindVertexArray(self.name);

	glCullFace(GL_BACK);
}


- (void)draw {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (useVertexBufferObjects) {
		glDrawElements(primType, numElements, elementType, 0);
	} else {
		glDrawElements(primType, numElements, elementType, elements);
	}
}


- (void)generateName {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	[nameLock lock];
	if (generatedName) {
		[nameLock unlock];
		return;
	}
	
	TKGetGLError();
	
	// Create a vertex array object (VAO) to cache model parameters
	glGenVertexArrays(1, &name);

	TKGetGLError();

	glBindVertexArray(name);
	
	TKGetGLError();
	
	if (useVertexBufferObjects) {
		
		GLuint posBufferName;
		
		// Create a vertex buffer object (VBO) to store positions
		glGenBuffers(1, &posBufferName);
		glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
		
		// Allocate and load position data into the VBO
		glBufferData(GL_ARRAY_BUFFER, positionArraySize, positions, GL_STATIC_DRAW);
		
		// Enable the position attribute for this VAO
		glEnableVertexAttribArray(TKVertexAttribPosition);
		
		TKGetGLError();
		
		// Get the size of the position type so we can set the stride properly
		GLsizei posTypeSize = TKGetGLTypeSize(positionType);
		
		// Set up parmeters for position attribute in the VAO including,
		//  size, type, stride, and offset in the currenly bound VAO
		// This also attaches the position VBO to the VAO
		glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader (see buildProgram)
							  positionSize, // How many elements are there per position?
							  positionType, // What is the type of this data?
							  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
							  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
							  BUFFER_OFFSET(0)); // What is the offset in the VBO to the position data?
		
		
		TKGetGLError();
		
		
		if (normals) {
			GLuint normalBufferName;
			
			// Create a vertex buffer object (VBO) to store positions
			glGenBuffers(1, &normalBufferName);
			glBindBuffer(GL_ARRAY_BUFFER, normalBufferName);
			
			// Allocate and load normal data into the VBO
			glBufferData(GL_ARRAY_BUFFER, normalArraySize, normals, GL_STATIC_DRAW);
			
			// Enable the normal attribute for this VAO
			glEnableVertexAttribArray(TKVertexAttribNormal);
			
			// Get the size of the normal type so we can set the stride properly
			GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
			
			// Set up parmeters for position attribute in the VAO including,
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the position VBO to the VAO
			glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
								  normalSize, // How many elements are there per normal?
								  normalType, // What is the type of this data?
								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
								  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
								  BUFFER_OFFSET(0)); // What is the offset in the VBO to the normal data?
		}
		
		TKGetGLError();
		
		if (texcoords) {
			GLuint texcoordBufferName;
			
			// Create a VBO to store texcoords
			glGenBuffers(1, &texcoordBufferName);
			glBindBuffer(GL_ARRAY_BUFFER, texcoordBufferName);
			
			// Allocate and load texcoord data into the VBO
			glBufferData(GL_ARRAY_BUFFER, texcoordArraySize, texcoords, GL_STATIC_DRAW);
			
			// Enable the texcoord attribute for this VAO
			glEnableVertexAttribArray(TKVertexAttribTexCoord0);
			
			// Get the size of the texcoord type so we can set the stride properly
			GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
			
			// Set up parmeters for texcoord attribute in the VAO including,
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the texcoord VBO to VAO
			glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
								  texcoordSize, // How many elements are there per texture coord?
								  texcoordType, // What is the type of this data in the array?
								  GL_TRUE,  // Do we want to normalize this data (0-1 range for fixed-point types)
								  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
								  BUFFER_OFFSET(0)); // What is the offset in the VBO to the texcoord data?
		}
		
		TKGetGLError();
		
		GLuint elementBufferName;
		
		// Create a VBO to vertex array elements
		// This also attaches the element array buffer to the VAO
		glGenBuffers(1, &elementBufferName);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
		
		// Allocate and load vertex array element data into VBO
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementArraySize, elements, GL_STATIC_DRAW);
		
		TKGetGLError();
		
		
	} else {
		
		// Enable the position attribute for this VAO
		glEnableVertexAttribArray(TKVertexAttribPosition);
		
		// Get the size of the position type so we can set the stride properly
		GLsizei posTypeSize = TKGetGLTypeSize(positionType);
		
		// Set up parmeters for position attribute in the VAO including,
		//  size, type, stride, and offset in the currenly bound VAO
		// This also attaches the position array in memory to the VAO
		glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader? (also see buildProgram)
							  positionSize, // How many elements are there per position?
							  positionType, // What is the type of this data
							  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
							  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
							  positions); // Where is the position data in memory?
		
		if (normals) {
			// Enable the normal attribute for this VAO
			glEnableVertexAttribArray(TKVertexAttribNormal);
			
			// Get the size of the normal type so we can set the stride properly
			GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
			
			// Set up parmeters for position attribute in the VAO including,
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the position VBO to the VAO
			glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
								  normalSize, // How many elements are there per normal?
								  normalType, // What is the type of this data?
								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
								  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
								  normals); // Where is normal data in memory?
		}
		if (texcoords) {
			// Enable the texcoord attribute for this VAO
			glEnableVertexAttribArray(TKVertexAttribTexCoord0);
			
			// Get the size of the texcoord type so we can set the stride properly
			GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
			
			// Set up parmeters for texcoord attribute in the VAO including,
			//   size, type, stride, and offset in the currenly bound VAO
			// This also attaches the texcoord array in memory to the VAO
			glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
								  texcoordSize, // How many elements are there per texture coord?
								  texcoordType, // What is the type of this data in the array?
								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-point types)
								  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
								  texcoords); // Where is the texcood data in memory?
		}
	}
	TKGetGLError();

	generatedName = YES;
	[nameLock unlock];
}




//- (void)generateVertexArrayObjectName {
//#if TK_DEBUG
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//	TKGetGLError();
//	
//	// Create a vertex array object (VAO) to cache model parameters
//	glGenVertexArrays(1, &name);
//
//	TKGetGLError();
//
//	glBindVertexArray(name);
//	
//	TKGetGLError();
//	
//	if (useVertexBufferObjects) {
//		
//		GLuint posBufferName;
//		
//		// Create a vertex buffer object (VBO) to store positions
//		glGenBuffers(1, &posBufferName);
//		glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
//		
//		// Allocate and load position data into the VBO
//		glBufferData(GL_ARRAY_BUFFER, positionArraySize, positions, GL_STATIC_DRAW);
//		
//		// Enable the position attribute for this VAO
//		glEnableVertexAttribArray(TKVertexAttribPosition);
//		
//		TKGetGLError();
//		
//		// Get the size of the position type so we can set the stride properly
//		GLsizei posTypeSize = TKGetGLTypeSize(positionType);
//		
//		// Set up parmeters for position attribute in the VAO including,
//		//  size, type, stride, and offset in the currenly bound VAO
//		// This also attaches the position VBO to the VAO
//		glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader (see buildProgram)
//							  positionSize, // How many elements are there per position?
//							  positionType, // What is the type of this data?
//							  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
//							  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
//							  BUFFER_OFFSET(0)); // What is the offset in the VBO to the position data?
//		
//		
//		TKGetGLError();
//		
//		
//		if (normals) {
//			GLuint normalBufferName;
//			
//			// Create a vertex buffer object (VBO) to store positions
//			glGenBuffers(1, &normalBufferName);
//			glBindBuffer(GL_ARRAY_BUFFER, normalBufferName);
//			
//			// Allocate and load normal data into the VBO
//			glBufferData(GL_ARRAY_BUFFER, normalArraySize, normals, GL_STATIC_DRAW);
//			
//			// Enable the normal attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribNormal);
//			
//			// Get the size of the normal type so we can set the stride properly
//			GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
//			
//			// Set up parmeters for position attribute in the VAO including,
//			//   size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the position VBO to the VAO
//			glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
//								  normalSize, // How many elements are there per normal?
//								  normalType, // What is the type of this data?
//								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
//								  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
//								  BUFFER_OFFSET(0)); // What is the offset in the VBO to the normal data?
//		}
//		
//		TKGetGLError();
//		
//		if (texcoords) {
//			GLuint texcoordBufferName;
//			
//			// Create a VBO to store texcoords
//			glGenBuffers(1, &texcoordBufferName);
//			glBindBuffer(GL_ARRAY_BUFFER, texcoordBufferName);
//			
//			// Allocate and load texcoord data into the VBO
//			glBufferData(GL_ARRAY_BUFFER, texcoordArraySize, texcoords, GL_STATIC_DRAW);
//			
//			// Enable the texcoord attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribTexCoord0);
//			
//			// Get the size of the texcoord type so we can set the stride properly
//			GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
//			
//			// Set up parmeters for texcoord attribute in the VAO including,
//			//   size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the texcoord VBO to VAO
//			glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
//								  texcoordSize, // How many elements are there per texture coord?
//								  texcoordType, // What is the type of this data in the array?
//								  GL_TRUE,  // Do we want to normalize this data (0-1 range for fixed-point types)
//								  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
//								  BUFFER_OFFSET(0)); // What is the offset in the VBO to the texcoord data?
//		}
//		
//		TKGetGLError();
//		
//		GLuint elementBufferName;
//		
//		// Create a VBO to vertex array elements
//		// This also attaches the element array buffer to the VAO
//		glGenBuffers(1, &elementBufferName);
//		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
//		
//		// Allocate and load vertex array element data into VBO
//		glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementArraySize, elements, GL_STATIC_DRAW);
//		
//		TKGetGLError();
//		
//		
//	} else {
//		
//		// Enable the position attribute for this VAO
//		glEnableVertexAttribArray(TKVertexAttribPosition);
//		
//		// Get the size of the position type so we can set the stride properly
//		GLsizei posTypeSize = TKGetGLTypeSize(positionType);
//		
//		// Set up parmeters for position attribute in the VAO including,
//		//  size, type, stride, and offset in the currenly bound VAO
//		// This also attaches the position array in memory to the VAO
//		glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader? (also see buildProgram)
//							  positionSize, // How many elements are there per position?
//							  positionType, // What is the type of this data
//							  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
//							  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
//							  positions); // Where is the position data in memory?
//		
//		if (normals) {
//			// Enable the normal attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribNormal);
//			
//			// Get the size of the normal type so we can set the stride properly
//			GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
//			
//			// Set up parmeters for position attribute in the VAO including,
//			//   size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the position VBO to the VAO
//			glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
//								  normalSize, // How many elements are there per normal?
//								  normalType, // What is the type of this data?
//								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
//								  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
//								  normals); // Where is normal data in memory?
//		}
//		if (texcoords) {
//			// Enable the texcoord attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribTexCoord0);
//			
//			// Get the size of the texcoord type so we can set the stride properly
//			GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
//			
//			// Set up parmeters for texcoord attribute in the VAO including,
//			//   size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the texcoord array in memory to the VAO
//			glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
//								  texcoordSize, // How many elements are there per texture coord?
//								  texcoordType, // What is the type of this data in the array?
//								  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-point types)
//								  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
//								  texcoords); // Where is the texcood data in memory?
//		}
//	}
//	TKGetGLError();
//	vertexArrayObjectGenerated = YES;
//}


- (void)destroyVertexArrayObjectWithName:(GLuint)vaoName {
	GLuint index;
	GLuint bufName;

	// Bind the VAO so we can get data from it
	glBindVertexArray(vaoName);
	// For every possible attribute set in the VAO
	for (index = 0; index < 16; index++) {
		// Get the VBO set for that attribute
		glGetVertexAttribiv(index, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, (GLint *)&bufName);

		// If there was a VBO set...
		if (bufName) {
			//...delete the VBO
			glDeleteBuffers(1, &bufName);
		}
	}

	// Get any element array VBO set in the VAO
	glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, (GLint *)&bufName);

	// If there was a element array VBO set in the VAO
	if (bufName) {
		//...delete the VBO
		glDeleteBuffers(1, &bufName);
	}
	// Finally, delete the VAO
	glDeleteVertexArrays(1, &vaoName);

	TKGetGLError();
//	vertexArrayObjectGenerated = NO;
}


- (BOOL)parseModelData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSUInteger currentOffset = 0;
	
	TKModelHeader header;
	
	if (![self haveEnoughBytesRemainingForObjectWithLength:sizeof(TKModelHeader) totalLength:[data length] currentOffset:currentOffset description:@"TKModelHeader"]) {
		return NO;
	}
	
	[data getBytes:&header range:NSMakeRange(currentOffset, sizeof(TKModelHeader))];
	
	currentOffset += sizeof(TKModelHeader);
	
	if (![[NSString stringWithCString:header.fileIdentifier encoding:NSASCIIStringEncoding] isEqualToString:TKAppleOpenGLDemoIdentifier]) {
		NSLog(@"[%@ %@] fileIdentifier != %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), TKAppleOpenGLDemoIdentifier);
		return NO;
	}
	
	if (header.majorVersion != 0 && header.minorVersion != 1) {
		NSLog(@"[%@ %@] header.majorVersion != 0 && header.minorVersion != 1", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	
	if (![self haveEnoughBytesRemainingForObjectWithLength:sizeof(TKModelTOC) totalLength:[data length] currentOffset:currentOffset description:@"TKModelTOC"]) {
		return NO;
	}
	
	
	TKModelTOC tableOfContents;
	
	[data getBytes:&tableOfContents range:NSMakeRange(currentOffset, sizeof(TKModelTOC))];
	
	currentOffset += sizeof(TKModelTOC);
	
	if (tableOfContents.attribHeaderSize > sizeof(TKModelAttributes)) {
		NSLog(@"[%@ %@] ERROR: tableOfContents.attribHeaderSize > sizeof(TKModelAttributes)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return NO;
	}
	
	TKModelAttributes attributes;
	
	[data getBytes:&attributes range:NSMakeRange(tableOfContents.byteElementOffset, tableOfContents.attribHeaderSize)];
	
	currentOffset = tableOfContents.byteElementOffset + tableOfContents.attribHeaderSize;
	
	elementArraySize = attributes.byteSize;
	elementType = attributes.datatype;
	numElements = attributes.numElements;
	
	
#if TARGET_OS_IPHONE
	
	// OpenGL ES cannot use UNSIGNED_INT elements
	// So if the model has UI element...
	
	if (elementType == GL_UNSIGNED_INT) {
		//...Load the UI elements and convert to UNSIGNED_SHORT
		
		GLubyte *uiElements = (GLubyte *)malloc(elementArraySize);
		elements = (GLubyte *)malloc(numElements * sizeof(GLushort));
		
		[data getBytes:uiElements range:NSMakeRange(currentOffset, elementArraySize)];
		
		GLuint elemNum = 0;
		
		for (elemNum = 0; elemNum < numElements; elemNum++) {
			//We can't handle this model if an element is out of the UNSIGNED_INT range
			if (((GLuint *)uiElements)[elemNum] >= 0xFFFF) {
				return NO;
			}
			((GLushort *)elements)[elemNum] = ((GLuint *)uiElements)[elemNum];
		}
		
		free(uiElements);
		elementType = GL_UNSIGNED_SHORT;
		elementArraySize = numElements * sizeof(GLushort);
		
		
	} else {
		elements = (GLubyte *)malloc(elementArraySize);
		
		[data getBytes:elements range:NSMakeRange(currentOffset, elementArraySize)];
		
	}
	
#else
	elements = (GLubyte *)malloc(elementArraySize);
	
	[data getBytes:elements range:NSMakeRange(currentOffset, elementArraySize)];
	
#endif
	
	
	currentOffset = tableOfContents.bytePositionOffset;
	
	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
	
	currentOffset += tableOfContents.attribHeaderSize;
	
	
	positionArraySize	= attributes.byteSize;
	positionType		= attributes.datatype;
	positionSize		= attributes.sizePerElement;
	
	numVertices			= attributes.numElements;
	
	positions = (GLubyte *)malloc(positionArraySize);
	
	[data getBytes:positions range:NSMakeRange(currentOffset, positionArraySize)];
	
	currentOffset = tableOfContents.byteTexcoordOffset;
	
	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
	
	currentOffset += tableOfContents.attribHeaderSize;
	
	texcoordArraySize	= attributes.byteSize;
	texcoordType		= attributes.datatype;
	texcoordSize		= attributes.sizePerElement;
	
	//Must have the same number of texcoords as positions
	if (numVertices != attributes.numElements) {
		return NO;
	}
	
	texcoords = (GLubyte *)malloc(texcoordArraySize);
	
	[data getBytes:texcoords range:NSMakeRange(currentOffset, texcoordArraySize)];
	
	currentOffset = tableOfContents.byteNormalOffset;
	
	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
	
	currentOffset += tableOfContents.attribHeaderSize;
	
	normalArraySize		= attributes.byteSize;
	normalType			= attributes.datatype;
	normalSize			= attributes.sizePerElement;
	
	//Must have the same number of normals as positions
	if (numVertices != attributes.numElements) {
		return NO;
	}
	
	normals = (GLubyte *)malloc(normalArraySize);
	
	[data getBytes:normals range:NSMakeRange(currentOffset, normalArraySize)];

	primType = GL_TRIANGLES;
	
	return YES;
}



- (NSString *)stringRepresentation {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\n", [super description]];
	[description appendFormat:@"	numVertices == %u\n", numVertices];
	[description appendFormat:@"	positionType == %@\n", NSStringFromOpenGLDataType(positionType)];
	[description appendFormat:@"	positionSize == %u\n", positionSize];
	[description appendFormat:@"	positionArraySize == %u\n", positionArraySize];
	
	[description appendFormat:@"	texcoordType == %@\n", NSStringFromOpenGLDataType(texcoordType)];
	[description appendFormat:@"	texcoordSize == %u\n", texcoordSize];
	[description appendFormat:@"	texcoordArraySize == %u\n", texcoordArraySize];
	
	[description appendFormat:@"	normalType == %@\n", NSStringFromOpenGLDataType(normalType)];
	[description appendFormat:@"	normalSize == %u\n", normalSize];
	[description appendFormat:@"	normalArraySize == %u\n", normalArraySize];
	
	[description appendFormat:@"	elementType == %@\n", NSStringFromOpenGLDataType(elementType)];
	[description appendFormat:@"	numElements == %u\n", numElements];
	[description appendFormat:@"	elementArraySize == %u\n", elementArraySize];
	
	[description appendFormat:@"	primType == %@\n", NSStringFromOpenGLDataType(primType)];

	[description appendFormat:@"	name == %u\n", name];
	
	[description appendFormat:@"	shaderProgram == %@\n", shaderProgram];

	[description appendFormat:@"	texture == %@\n", texture];

//	[description appendFormat:@"	position == %@\n", NSStringFromVector3(position)];
//	
//	[description appendFormat:@"	rotation == %@\n", NSStringFromVector3(rotation)];
	
	return description;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\n", [super description]];
	[description appendFormat:@"	numVertices == %u\n", numVertices];
	[description appendFormat:@"	positionType == %@\n", NSStringFromOpenGLDataType(positionType)];
	[description appendFormat:@"	positionSize == %u\n", positionSize];
	[description appendFormat:@"	positionArraySize == %u\n", positionArraySize];
	
	[description appendFormat:@"	texcoordType == %@\n", NSStringFromOpenGLDataType(texcoordType)];
	[description appendFormat:@"	texcoordSize == %u\n", texcoordSize];
	[description appendFormat:@"	texcoordArraySize == %u\n", texcoordArraySize];
	
	[description appendFormat:@"	normalType == %@\n", NSStringFromOpenGLDataType(normalType)];
	[description appendFormat:@"	normalSize == %u\n", normalSize];
	[description appendFormat:@"	normalArraySize == %u\n", normalArraySize];
	
	[description appendFormat:@"	elementType == %@\n", NSStringFromOpenGLDataType(elementType)];
	[description appendFormat:@"	numElements == %u\n", numElements];
	[description appendFormat:@"	elementArraySize == %u\n", elementArraySize];
	
	[description appendFormat:@"	primType == %@\n", NSStringFromOpenGLDataType(primType)];

	[description appendFormat:@"	name == %u\n", name];
	
	[description appendFormat:@"	shaderProgram == %@\n", shaderProgram];

	[description appendFormat:@"	texture == %@\n", texture];

//	[description appendFormat:@"	position == %@\n", NSStringFromVector3(position)];
//	
//	[description appendFormat:@"	rotation == %@\n", NSStringFromVector3(rotation)];
	
	return description;
}


- (BOOL)haveEnoughBytesRemainingForObjectWithLength:(NSUInteger)neededLength
										totalLength:(NSUInteger)totalLength
									  currentOffset:(NSUInteger)currentOffset
										description:(NSString *)objectTypeDescription {
	if (currentOffset + neededLength > totalLength) {
		NSLog(@"[%@ %@] Not enough bytes (bytesLeft == %lu, bytesNeeded == %lu) to parse %@",
			  NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)(totalLength - currentOffset), (unsigned long)neededLength, objectTypeDescription);
		return NO;
	}
	return YES;
}




@end



