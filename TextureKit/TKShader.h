//
//  TKShader.h
//  Texture Kit
//
//  Created by Mark Douma on 11/28/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//


#import <TextureKit/TKOpenGLObject.h>


enum {
	TKVertexShaderType		= 0,
	TKFragmentShaderType	= 1,
	TKUnknownShaderType		= 2
};
typedef NSUInteger TKShaderType;


@interface TKShader : TKOpenGLObject {
	NSString			*source;
	
	NSString			*displayName;
	
	TKShaderType		shaderType;
	
	GLfloat				shadingLanguageVersion;
	
	BOOL				compiled;
	
	BOOL				withNormals;
	BOOL				withTexcoords;
	
}

+ (NSArray *)shadersNamed:(NSString *)filename;


+ (id)shaderWithContentsOfFile:(NSString *)filePath error:(NSError **)outError;
+ (id)shaderWithContentsOfURL:(NSURL *)URL error:(NSError **)outError;

+ (id)shaderWithSource:(NSString *)sourceString shaderType:(TKShaderType)aShaderType displayName:(NSString *)aDisplayName error:(NSError **)outError;


- (id)initWithContentsOfFile:(NSString *)filePath error:(NSError **)outError;
- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)outError;

- (id)initWithSource:(NSString *)sourceString shaderType:(TKShaderType)aShaderType displayName:(NSString *)aDisplayName error:(NSError **)outError;


+ (GLfloat)defaultShadingLanguageVersion;
+ (void)setDefaultShadingLanguageVersion:(GLfloat)version;


@property (nonatomic, copy) NSString *source;


@property (readonly, nonatomic, assign) TKShaderType shaderType;

@property (nonatomic, retain) NSString *displayName;

@property (nonatomic, assign) GLfloat shadingLanguageVersion;


@property (readonly, nonatomic, assign, getter=isCompiled) BOOL compiled;


@property (nonatomic, assign) BOOL withNormals;
@property (nonatomic, assign) BOOL withTexcoords;


- (BOOL)compileWithLog:(NSString **)outCompileLog;


@end



