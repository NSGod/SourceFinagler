//
//  TKOBJModel.m
//  Texture Kit
//
//  Created by Mark Douma on 11/27/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKOBJModel.h>
#import <TextureKit/TKOpenGLBase.h>
#import <TextureKit/TKTexture.h>
#import <TextureKit/TKShader.h>
#import <TextureKit/TKOBJParts.h>

#import "TKPrivateInterfaces.h"


#define TK_DEBUG 1



//@interface TKOBJModel ()
//
////@property (nonatomic, assign) GLuint vertexArrayObjectName;
//
//- (void)destroyVertexArrayObjectWithName:(GLuint)vaoName;
//
//@end



@implementation TKOBJModel


- (id)initWithData:(NSData *)data {
	NSParameterAssert(data != nil);
	if ((self = [super init])) {
		useVertexBufferObjects = YES;
		if (![self parseModelData:data]) {
			
		}
	}
	return self;
}


//- (void)dealloc {
//	
//	[super dealloc];
//}



- (BOOL)parseModelData:(NSData *)data {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	return NO;
	
}
	
//	NSUInteger currentOffset = 0;
	
	
	
	
	
//	elementArraySize = attributes.byteSize;
//	elementType = attributes.datatype;
//	numElements = attributes.numElements;
	
//	
//	// OpenGL ES cannot use UNSIGNED_INT elements
//	// So if the model has UI element...
//	if (elementType == GL_UNSIGNED_INT) {
//		//...Load the UI elements and convert to UNSIGNED_SHORT
//		
//		GLubyte *uiElements = (GLubyte *)malloc(elementArraySize);
//		elements = (GLubyte *)malloc(numElements * sizeof(GLushort));
//		
//		[data getBytes:uiElements range:NSMakeRange(currentOffset, elementArraySize)];
//		
//		GLuint elemNum = 0;
//		
//		for (elemNum = 0; elemNum < numElements; elemNum++) {
//			//We can't handle this model if an element is out of the UNSIGNED_INT range
//			if (((GLuint *)uiElements)[elemNum] >= 0xFFFF) {
//				return NO;
//			}
//			((GLushort *)elements)[elemNum] = ((GLuint *)uiElements)[elemNum];
//		}
//		
//		free(uiElements);
//		elementType = GL_UNSIGNED_SHORT;
//		elementArraySize = numElements * sizeof(GLushort);
//		
//		
//	} else {
//		elements = (GLubyte *)malloc(elementArraySize);
//		
//		[data getBytes:elements range:NSMakeRange(currentOffset, elementArraySize)];
//		
//		
//	}
	
	
//	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
//	
//	currentOffset += tableOfContents.attribHeaderSize;
	
	
//	positionArraySize	= attributes.byteSize;
//	positionType		= attributes.datatype;
//	positionSize		= attributes.sizePerElement;
//	numVertices			= attributes.numElements;
	
//	positions = (GLubyte *)malloc(positionArraySize);
//	
//	[data getBytes:positions range:NSMakeRange(currentOffset, positionArraySize)];
	
//	currentOffset = tableOfContents.byteTexcoordOffset;
//	
//	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
//	
//	currentOffset += tableOfContents.attribHeaderSize;
//	
//	texcoordArraySize	= attributes.byteSize;
//	texcoordType		= attributes.datatype;
//	texcoordSize		= attributes.sizePerElement;
//	
//	//Must have the same number of texcoords as positions
//	if (numVertices != attributes.numElements) {
//		return NO;
//	}
	
//	texcoords = (GLubyte *)malloc(texcoordArraySize);
//	
//	[data getBytes:texcoords range:NSMakeRange(currentOffset, texcoordArraySize)];
	
//	currentOffset = tableOfContents.byteNormalOffset;
//	
//	[data getBytes:&attributes range:NSMakeRange(currentOffset, tableOfContents.attribHeaderSize)];
//	
//	currentOffset += tableOfContents.attribHeaderSize;
//	
//	normalArraySize		= attributes.byteSize;
//	normalType			= attributes.datatype;
//	normalSize			= attributes.sizePerElement;
//	
//	//Must have the same number of normals as positions
//	if (numVertices != attributes.numElements) {
//		return NO;
//	}
	
//	normals = (GLubyte *)malloc(normalArraySize);
//	
//	[data getBytes:normals range:NSMakeRange(currentOffset, normalArraySize)];
	
//	return YES;
//}



//- (BOOL)haveEnoughBytesRemainingForObjectWithLength:(NSUInteger)neededLength
//										totalLength:(NSUInteger)totalLength
//									  currentOffset:(NSUInteger)currentOffset
//										description:(NSString *)objectTypeDescription {
//	if (currentOffset + neededLength > totalLength) {
//		NSLog(@"[%@ %@] Not enough bytes (bytesLeft == %lu, bytesNeeded == %lu) to parse %@",
//			  NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)(totalLength - currentOffset), (unsigned long)neededLength, objectTypeDescription);
//		return NO;
//	}
//	return YES;
//}


//static GLsizei TKGetGLTypeSize(GLenum type) {
//	switch (type) {
//	case GL_BYTE:
//		return sizeof(GLbyte);
//	case GL_UNSIGNED_BYTE:
//		return sizeof(GLubyte);
//	case GL_SHORT:
//		return sizeof(GLshort);
//	case GL_UNSIGNED_SHORT:
//		return sizeof(GLushort);
//	case GL_INT:
//		return sizeof(GLint);
//	case GL_UNSIGNED_INT:
//		return sizeof(GLuint);
//	case GL_FLOAT:
//		return sizeof(GLfloat);
//	}
//	return 0;
//}


//- (GLuint)vertexArrayObjectName {
//	if (vertexArrayObjectName == 0) {
//#if TK_DEBUG
//		NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//#endif
//
//		// Create a vertex array object (VAO) to cache model parameters
//		glGenVertexArrays(1, &vertexArrayObjectName);
//		glBindVertexArray(vertexArrayObjectName);
//		
//		
//		if (useVertexBufferObjects) {
//			
//			GLuint posBufferName;
//			
//			// Create a vertex buffer object (VBO) to store positions
//			glGenBuffers(1, &posBufferName);
//			glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
//			
//			// Allocate and load position data into the VBO
//			glBufferData(GL_ARRAY_BUFFER, positionArraySize, positions, GL_STATIC_DRAW);
//			
//			// Enable the position attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribPosition);
//			
//			// Get the size of the position type so we can set the stride properly
//			GLsizei posTypeSize = TKGetGLTypeSize(positionType);
//			
//			// Set up parmeters for position attribute in the VAO including,
//			//  size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the position VBO to the VAO
//			glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader (see buildProgram)
//								  positionSize, // How many elements are there per position?
//								  positionType, // What is the type of this data?
//								  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
//								  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
//								  BUFFER_OFFSET(0)); // What is the offset in the VBO to the position data?
//			
//			
//			if (normals) {
//				GLuint normalBufferName;
//				
//				// Create a vertex buffer object (VBO) to store positions
//				glGenBuffers(1, &normalBufferName);
//				glBindBuffer(GL_ARRAY_BUFFER, normalBufferName);
//				
//				// Allocate and load normal data into the VBO
//				glBufferData(GL_ARRAY_BUFFER, normalArraySize, normals, GL_STATIC_DRAW);
//				
//				// Enable the normal attribute for this VAO
//				glEnableVertexAttribArray(TKVertexAttribNormal);
//				
//				// Get the size of the normal type so we can set the stride properly
//				GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
//				
//				// Set up parmeters for position attribute in the VAO including,
//				//   size, type, stride, and offset in the currenly bound VAO
//				// This also attaches the position VBO to the VAO
//				glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
//									  normalSize, // How many elements are there per normal?
//									  normalType, // What is the type of this data?
//									  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
//									  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
//									  BUFFER_OFFSET(0)); // What is the offset in the VBO to the normal data?
//			}
//			if (texcoords) {
//				GLuint texcoordBufferName;
//				
//				// Create a VBO to store texcoords
//				glGenBuffers(1, &texcoordBufferName);
//				glBindBuffer(GL_ARRAY_BUFFER, texcoordBufferName);
//				
//				// Allocate and load texcoord data into the VBO
//				glBufferData(GL_ARRAY_BUFFER, texcoordArraySize, texcoords, GL_STATIC_DRAW);
//				
//				// Enable the texcoord attribute for this VAO
//				glEnableVertexAttribArray(TKVertexAttribTexCoord0);
//				
//				// Get the size of the texcoord type so we can set the stride properly
//				GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
//				
//				// Set up parmeters for texcoord attribute in the VAO including,
//				//   size, type, stride, and offset in the currenly bound VAO
//				// This also attaches the texcoord VBO to VAO
//				glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
//									  texcoordSize, // How many elements are there per texture coord?
//									  texcoordType, // What is the type of this data in the array?
//									  GL_TRUE,  // Do we want to normalize this data (0-1 range for fixed-point types)
//									  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
//									  BUFFER_OFFSET(0)); // What is the offset in the VBO to the texcoord data?
//			}
//			GLuint elementBufferName;
//			
//			// Create a VBO to vertex array elements
//			// This also attaches the element array buffer to the VAO
//			glGenBuffers(1, &elementBufferName);
//			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBufferName);
//			
//			// Allocate and load vertex array element data into VBO
//			glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementArraySize, elements, GL_STATIC_DRAW);
//		} else {
//			
//			// Enable the position attribute for this VAO
//			glEnableVertexAttribArray(TKVertexAttribPosition);
//			
//			// Get the size of the position type so we can set the stride properly
//			GLsizei posTypeSize = TKGetGLTypeSize(positionType);
//			
//			// Set up parmeters for position attribute in the VAO including,
//			//  size, type, stride, and offset in the currenly bound VAO
//			// This also attaches the position array in memory to the VAO
//			glVertexAttribPointer(TKVertexAttribPosition, // What attribute index will this array feed in the vertex shader? (also see buildProgram)
//								  positionSize, // How many elements are there per position?
//								  positionType, // What is the type of this data
//								  GL_FALSE,     // Do we want to normalize this data (0-1 range for fixed-pont types)
//								  positionSize * posTypeSize, // What is the stride (i.e. bytes between positions)?
//								  positions); // Where is the position data in memory?
//			
//			if (normals) {
//				// Enable the normal attribute for this VAO
//				glEnableVertexAttribArray(TKVertexAttribNormal);
//				
//				// Get the size of the normal type so we can set the stride properly
//				GLsizei normalTypeSize = TKGetGLTypeSize(normalType);
//				
//				// Set up parmeters for position attribute in the VAO including,
//				//   size, type, stride, and offset in the currenly bound VAO
//				// This also attaches the position VBO to the VAO
//				glVertexAttribPointer(TKVertexAttribNormal, // What attribute index will this array feed in the vertex shader (see buildProgram)
//									  normalSize, // How many elements are there per normal?
//									  normalType, // What is the type of this data?
//									  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-pont types)
//									  normalSize * normalTypeSize, // What is the stride (i.e. bytes between normals)?
//									  normals); // Where is normal data in memory?
//			}
//			if (texcoords) {
//				// Enable the texcoord attribute for this VAO
//				glEnableVertexAttribArray(TKVertexAttribTexCoord0);
//				
//				// Get the size of the texcoord type so we can set the stride properly
//				GLsizei texcoordTypeSize = TKGetGLTypeSize(texcoordType);
//				
//				// Set up parmeters for texcoord attribute in the VAO including,
//				//   size, type, stride, and offset in the currenly bound VAO
//				// This also attaches the texcoord array in memory to the VAO
//				glVertexAttribPointer(TKVertexAttribTexCoord0, // What attribute index will this array feed in the vertex shader (see buildProgram)
//									  texcoordSize, // How many elements are there per texture coord?
//									  texcoordType, // What is the type of this data in the array?
//									  GL_FALSE, // Do we want to normalize this data (0-1 range for fixed-point types)
//									  texcoordSize * texcoordTypeSize, // What is the stride (i.e. bytes between texcoords)?
//									  texcoords); // Where is the texcood data in memory?
//			}
//		}
//		TKGetGLError();
//	}
//	return vertexArrayObjectName;
//}



@end










