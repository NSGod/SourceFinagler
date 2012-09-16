//
//  TKShaderProgram.h
//  Texture Kit
//
//  Created by Mark Douma on 12/15/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLObject.h>


@class TKModel;
@class TKShader;


// Named vertex attributes for mapping GLKEffects logic to client vertex attrib enables
enum {
    TKVertexAttribPosition,
    TKVertexAttribNormal,
//    TKVertexAttribColor,
    TKVertexAttribTexCoord0,
//    TKVertexAttribTexCoord1,
};
typedef NSUInteger TKVertexAttrib;



enum {
	TKVariableTypeAttrib		= 0,
	TKVariableTypeUniform		= 1
};
typedef NSUInteger TKVariableType;


@interface TKVariable : NSObject {
	NSString				*name;
	TKVariableType			variableType;
	GLuint					index;
	GLsizei					size;
	GLenum					type;
}

+ (id)variableWithName:(NSString *)aName variableType:(TKVariableType)aVariableType index:(GLuint)anIndex size:(GLsizei)aSize type:(GLenum)aType;
- (id)initWithName:(NSString *)aName variableType:(TKVariableType)aVariableType index:(GLuint)anIndex size:(GLsizei)aSize type:(GLenum)aType;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) TKVariableType variableType;
@property (nonatomic, assign) GLuint index;
@property (nonatomic, assign) GLsizei size;
@property (nonatomic, assign) GLenum type;

@end



@interface TKShaderProgram : TKOpenGLObject {
	
	NSMutableArray				*attachedShaders;
	
	NSString					*displayName;
	
	NSMutableArray				*attributeKeys;
	
	NSMutableDictionary			*attributesAndIndexes;
	
	NSMutableDictionary			*uniformsAndIndexes;
	
	BOOL						linked;
	
	BOOL						valid;
	
	BOOL						withNormals;
	BOOL						withTexcoords;
	
}

+ (id)shaderProgramNamed:(NSString *)filename;
- (id)initWithShaders:(NSArray *)aShaders displayName:(NSString *)aDisplayName;

- (NSArray *)attachedShaders;
- (void)setAttachedShaders:(NSArray *)shaders;
- (void)attachShader:(TKShader *)shader;
- (void)detachShader:(TKShader *)shader;

- (BOOL)linkWithLog:(NSString **)outCompileLog;

- (NSArray *)attributeKeys;
- (NSArray *)uniformKeys;

- (void)setValue:(id)value forAttribKey:(NSString *)key;
- (void)setValue:(id)value forUniformKey:(NSString *)key;

- (void)useProgram;

@property (nonatomic, retain) NSString *displayName;


@property (readonly, nonatomic, assign, getter=isLinked) BOOL linked;
@property (readonly, nonatomic, assign, getter=isValid) BOOL valid;


@property (nonatomic, assign) BOOL withNormals;
@property (nonatomic, assign) BOOL withTexcoords;


@end


