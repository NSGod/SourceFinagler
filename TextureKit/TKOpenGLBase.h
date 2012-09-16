//
//  TKOpenGLBase.h
//  Texture Kit
//
//  Created by Mark Douma on 12/1/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TextureKitDefines.h>


#if TARGET_OS_IPHONE
	#import <OpenGLES/ES2/gl.h>
	#import <OpenGLES/ES2/glext.h>
#else
	#import <OpenGL/OpenGL.h>
	// OpenGL 3.2 is only supported on MacOS X Lion and later
	// CGL_VERSION_1_3 is defined as 1 on MacOS X Lion and later
	#if CGL_VERSION_1_3
		// Set to 0 to run on the Legacy OpenGL Profile
		#define TK_ENABLE_OPENGL3 1
	#else
		#define TK_ENABLE_OPENGL3 0
	#endif

	#if TK_ENABLE_OPENGL3
		#import <OpenGL/gl3.h>
	#else
		#error blah
		#import <OpenGL/gl.h>
	#endif
#endif


#if TARGET_OS_IPHONE
	#define glBindVertexArray glBindVertexArrayOES
	#define glGenVertexArrays glGenVertexArraysOES
	#define glDeleteVertexArrays glDeleteVertexArraysOES
#else
	#if TK_ENABLE_OPENGL3
		#define glBindVertexArray glBindVertexArray
		#define glGenVertexArrays glGenVertexArrays
		#define glGenerateMipmap glGenerateMipmap
		#define glDeleteVertexArrays glDeleteVertexArrays
	#else
		#define glBindVertexArray glBindVertexArrayAPPLE
		#define glGenVertexArrays glGenVertexArraysAPPLE
		#define glGenerateMipmap glGenerateMipmapEXT
		#define glDeleteVertexArrays glDeleteVertexArraysAPPLE
	#endif
#endif


typedef struct {
	NSString		*description;
	GLenum			dataType;
} TKOpenGLDataTypeMapping;

static const TKOpenGLDataTypeMapping TKOpenGLDataTypeMappingTable[] = {
	{@"GL_BOOL",				GL_BOOL},
	{@"GL_BYTE",				GL_BYTE},
	{@"GL_UNSIGNED_BYTE",		GL_UNSIGNED_BYTE},
	{@"GL_SHORT",				GL_SHORT},
	{@"GL_UNSIGNED_SHORT",		GL_UNSIGNED_SHORT},
	{@"GL_INT",					GL_INT},
	{@"GL_UNSIGNED_INT",		GL_UNSIGNED_INT},
	{@"GL_FLOAT",				GL_FLOAT},
	{@"GL_DOUBLE",				GL_DOUBLE},
	{@"GL_FLOAT_VEC2",			GL_FLOAT_VEC2},
	{@"GL_FLOAT_VEC3",			GL_FLOAT_VEC3},
	{@"GL_FLOAT_VEC4",			GL_FLOAT_VEC4},
	{@"GL_FLOAT_MAT2",			GL_FLOAT_MAT2},
	{@"GL_FLOAT_MAT3",			GL_FLOAT_MAT3},
	{@"GL_FLOAT_MAT4",			GL_FLOAT_MAT4},
	{@"GL_INT_VEC2",			GL_INT_VEC2},
	{@"GL_INT_VEC3",			GL_INT_VEC3},
	{@"GL_INT_VEC4",			GL_INT_VEC4},
	{@"GL_SAMPLER_1D",			GL_SAMPLER_1D},
	{@"GL_SAMPLER_2D",			GL_SAMPLER_2D},
	{@"GL_SAMPLER_3D",			GL_SAMPLER_3D},
	{@"GL_SAMPLER_CUBE",		GL_SAMPLER_CUBE},
	{@"GL_POINTS",				GL_POINTS},
	{@"GL_LINES",				GL_LINES},
	{@"GL_LINE_LOOP",			GL_LINE_LOOP},
	{@"GL_LINE_STRIP",			GL_LINE_STRIP},
	{@"GL_TRIANGLES",			GL_TRIANGLES},
	{@"GL_TRIANGLE_STRIP",		GL_TRIANGLE_STRIP},
	{@"GL_TRIANGLE_FAN",		GL_TRIANGLE_FAN},
#if !(TK_ENABLE_OPENGL3)
	{@"GL_QUADS",					GL_QUADS},
#endif
};
static const NSUInteger TKOpenGLDataMappingTableCount = sizeof(TKOpenGLDataTypeMappingTable)/sizeof(TKOpenGLDataTypeMappingTable[0]);

TEXTUREKIT_INLINE NSString *NSStringFromOpenGLDataType(GLenum dataType) {
	for (NSUInteger i = 0; i < TKOpenGLDataMappingTableCount; i++) {
		if (TKOpenGLDataTypeMappingTable[i].dataType == dataType) {
			return TKOpenGLDataTypeMappingTable[i].description;
		}
	}
	return [NSString stringWithFormat:@"<unknown dataType> %u (0x%x)", dataType, dataType];
}


TEXTUREKIT_INLINE GLsizei TKGetGLTypeSize(GLenum type) {
	switch(type) {
		case GL_BYTE:
			return sizeof(GLbyte);
		case GL_UNSIGNED_BYTE:
			return sizeof(GLubyte);
		case GL_SHORT:
			return sizeof(GLshort);
		case GL_UNSIGNED_SHORT:
			return sizeof(GLushort);
		case GL_INT:
			return sizeof(GLint);
		case GL_UNSIGNED_INT:
			return sizeof(GLuint);
		case GL_FLOAT:
			return sizeof(GLfloat);
	}
	return 0;
}


#define BUFFER_OFFSET(i) ((char *)NULL + (i))



#define TKGetGLError()                                    \
	{                                                       \
		GLenum err = glGetError();                          \
		while (err != GL_NO_ERROR) {                        \
			NSLog(@"GLError %s set in File:%s Line:%d\n",   \
			      TKGetGLErrorString(err),                  \
			      __FILE__,                               \
			      __LINE__);                              \
			err = glGetError();                             \
		}                                                   \
	}



static inline const char *TKGetGLErrorString(GLenum error) {
	const char *str = NULL;
	switch (error) {
		case GL_NO_ERROR :
			str = "GL_NO_ERROR";
			break;
		case GL_INVALID_ENUM :
			str = "GL_INVALID_ENUM";
			break;
		case GL_INVALID_VALUE :
			str = "GL_INVALID_VALUE";
			break;
		case GL_INVALID_OPERATION :
			str = "GL_INVALID_OPERATION";
			break;		
#if defined __gl_h_ || defined __gl3_h_
		case GL_OUT_OF_MEMORY :
			str = "GL_OUT_OF_MEMORY";
			break;
		case GL_INVALID_FRAMEBUFFER_OPERATION :
			str = "GL_INVALID_FRAMEBUFFER_OPERATION";
			break;
#endif
#if defined __gl_h_
		case GL_STACK_OVERFLOW :
			str = "GL_STACK_OVERFLOW";
			break;
		case GL_STACK_UNDERFLOW :
			str = "GL_STACK_UNDERFLOW";
			break;
		case GL_TABLE_TOO_LARGE :
			str = "GL_TABLE_TOO_LARGE";
			break;
#endif
		default:
			str = "(ERROR: Unknown Error Enum)";
			break;
	}
	return str;
}


