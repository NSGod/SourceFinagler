//
//  TKShaderProgram.m
//  Texture Kit
//
//  Created by Mark Douma on 12/15/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKShaderProgram.h>
#import <TextureKit/TKShader.h>
#import <TextureKit/TKValueAdditions.h>
#import <TextureKit/TKModel.h>


#define TK_DEBUG 1

static NSString * const TKAttribPrefixKey			= @"glAttrib.";
static NSString * const TKUniformPrefixKey			= @"glUniform.";



static inline NSString *TKKeyPathFromAttribKey(NSString *attribKey) {
	NSCAssert(attribKey != nil, @"attribKey != nil");
	return [NSString stringWithFormat:@"%@%@",TKAttribPrefixKey, attribKey];
}

static inline NSString *TKKeyPathFromUniformKey(NSString *uniformKey) {
	NSCAssert(uniformKey != nil, @"uniformKey != nil");
	return [NSString stringWithFormat:@"%@%@",TKUniformPrefixKey, uniformKey];
}

static inline NSString *TKAttribKeyFromKeyPath(NSString *attribKeyPath) {
	if ([attribKeyPath hasPrefix:TKAttribPrefixKey]) {
		return [attribKeyPath substringFromIndex:[TKAttribPrefixKey length]];
	}
	return attribKeyPath;
}

static inline NSString *TKUniformKeyFromKeyPath(NSString *uniformKeyPath) {
	if ([uniformKeyPath hasPrefix:TKUniformPrefixKey]) {
		return [uniformKeyPath substringFromIndex:[TKUniformPrefixKey length]];
	}
	return uniformKeyPath;
}



@implementation TKVariable

@synthesize name;
@synthesize variableType;
@synthesize index;
@synthesize size;
@synthesize type;


+ (id)variableWithName:(NSString *)aName variableType:(TKVariableType)aVariableType index:(GLuint)anIndex size:(GLsizei)aSize type:(GLenum)aType {
	return [[[[self class] alloc] initWithName:aName variableType:aVariableType index:anIndex size:aSize type:aType] autorelease];
}


- (id)initWithName:(NSString *)aName variableType:(TKVariableType)aVariableType index:(GLuint)anIndex size:(GLsizei)aSize type:(GLenum)aType {
	if ((self = [super init])) {
		name = [aName retain];
		variableType = aVariableType;
		index = anIndex;
		size = aSize;
		type = aType;
	}
	return self;
}

- (void)dealloc {
	[name release];
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@,	", [super description]];
	[description appendFormat:@"%@, ", name];
	[description appendFormat:@"variableType == %@, ", (variableType == TKVariableTypeAttrib ? @"TKVariableTypeAttrib" : @"TKVariableTypeUniform")];
	[description appendFormat:@"index == %u, ", (unsigned int)index];
	[description appendFormat:@"size == %u, ", (unsigned int)size];
	[description appendFormat:@"type == %@", NSStringFromOpenGLDataType(type)];
	return description;
}


@end




@interface TKShaderProgram ()

@property (nonatomic, assign, getter=isLinked) BOOL linked;
@property (nonatomic, assign, getter=isValid) BOOL valid;

@end


@implementation TKShaderProgram

@synthesize displayName;

@synthesize valid;
@synthesize linked;

@synthesize withNormals;
@synthesize withTexcoords;


+ (id)shaderProgramNamed:(NSString *)filename {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), filename);
#endif
	return [[[[self class] alloc] initWithShaders:[TKShader shadersNamed:filename] displayName:filename] autorelease];
}


- (id)initWithShaders:(NSArray *)aShaders displayName:(NSString *)aDisplayName {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if ((self = [super init])) {
		attachedShaders = [[NSMutableArray alloc] init];
		[attachedShaders setArray:aShaders];
		
		displayName = [aDisplayName retain];
		
		attributeKeys = [[NSMutableArray alloc] init];
		attributesAndIndexes = [[NSMutableDictionary alloc] init];
		uniformsAndIndexes = [[NSMutableDictionary alloc] init];
		
//		[self generateName];
	}
	return self;
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	glDeleteProgram(name);
	glUseProgram(0);
	[attachedShaders release];
	[displayName release];
	[attributeKeys release];
	[attributesAndIndexes release];
	[uniformsAndIndexes release];
	[super dealloc];
}


- (NSArray *)attachedShaders {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	return [[attachedShaders copy] autorelease];
}


- (void)setAttachedShaders:(NSArray *)shaders {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	[attachedShaders setArray:shaders];
	[self setValid:NO];
	[self setLinked:NO];
	generatedName = NO;
}


- (void)attachShader:(TKShader *)shader {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	NSParameterAssert(shader != nil);
	
	[attachedShaders addObject:shader];
	
	[self setLinked:NO];
	[self setValid:NO];
	
	generatedName = NO;
}


- (void)detachShader:(TKShader *)shader {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	NSParameterAssert(shader != nil);
	
	[attachedShaders removeObject:shader];
	
	[self setLinked:NO];
	[self setValid:NO];
	
	generatedName = NO;
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
	
	NSString *outputCompileLog = nil;
	if (![self linkWithLog:&outputCompileLog]) {
		
	}
	
	generatedName = YES;
	[nameLock unlock];
}



//- (void)generateProgram {
//#if TK_DEBUG
//	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
//#endif
//	NSString *outputCompileLog = nil;
//	if (![self linkWithLog:&outputCompileLog]) {
//		
//	}
//}


- (BOOL)linkWithLog:(NSString **)outCompileLog {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (self.isLinked && self.isValid && generatedName) return YES;
	
	[self setLinked:NO];
	[self setValid:NO];
	
	name = glCreateProgram();
	
	// Indicate the attribute indicies on which vertex arrays will be
	//  set with glVertexAttribPointer
	//  See buildVAO to see where vertex arrays are actually set
	glBindAttribLocation(name, TKVertexAttribPosition, "inPosition");

	if (withNormals) {
		glBindAttribLocation(name, TKVertexAttribNormal, "inNormal");
	}
	if (withTexcoords) {
		glBindAttribLocation(name, TKVertexAttribTexCoord0, "inTexcoord");
	}
	
	NSMutableString *mOutputLog = [NSMutableString string];
	
	NSString *outputLog = nil;
	
	for (TKShader *shader in attachedShaders) {
		if (![shader isCompiled]) {
			if (![shader compileWithLog:&outputLog]) {
				NSLog(@"[%@ %@] failed to compile shader; shader == %@\n outputLog == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), shader, outputLog);
				if (outCompileLog) [mOutputLog appendFormat:@"%@\n", outputLog];
				continue;
			}
		}
		
		glAttachShader(name, shader.name);
	}
	
	
	GLint logLength, status;
	
	
	//////////////////////
	// Link the program //
	//////////////////////
	
	glLinkProgram(name);
	glGetProgramiv(name, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(name, logLength, &logLength, log);
		NSLog(@"[%@ %@] %@ - Program link log:\n%s\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName, log);
		if (outCompileLog) [mOutputLog appendFormat:@"%@\n", [NSString stringWithUTF8String:log]];
		free(log);
	}
	glGetProgramiv(name, GL_LINK_STATUS, &status);
	if (status == 0) {
		NSLog(@"[%@ %@] %@ - Failed to link program", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
		if (outCompileLog) *outCompileLog = mOutputLog;
		return NO;
	}
	
	[self setLinked:YES];
	
	
	glValidateProgram(name);
	glGetProgramiv(name, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetProgramInfoLog(name, logLength, &logLength, log);
		NSLog(@"[%@ %@] %@ - Program validate log:\n%s\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName, log);
		if (outCompileLog) [mOutputLog appendFormat:@"%@\n", [NSString stringWithUTF8String:log]];
		free(log);
	}
	
	glGetProgramiv(name, GL_VALIDATE_STATUS, &status);
	if (status == 0) {
		NSLog(@"[%@ %@] %@ - Failed to validate program", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
		if (outCompileLog) *outCompileLog = mOutputLog;
		return NO;
	}
	
	[self setValid:YES];
	
	glUseProgram(name);
	
	GLint count = 0;
	
	glGetProgramiv(name, GL_ACTIVE_ATTRIBUTES, &count);
	
	GLsizei maxAttribLength = 0;
	
	glGetProgramiv(name, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttribLength);
	
	GLchar *attribName = (GLchar *)malloc(maxAttribLength);
	
	for (GLint i = 0; i < count; i++) {
		GLsizei size = 0;
		GLenum type = 0;
		
		glGetActiveAttrib(name, i, maxAttribLength, NULL, &size, &type, attribName);
		
		NSString *attribNameString = [NSString stringWithUTF8String:attribName];
		
		TKVariable *attrib = [TKVariable variableWithName:attribNameString variableType:TKVariableTypeAttrib index:i size:size type:type];
		
		if (attrib) [attributesAndIndexes setObject:attrib forKey:[NSNumber numberWithUnsignedInt:i]];
		
	}
	
	free(attribName);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] %@ attributesAndIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName, attributesAndIndexes);
#endif
	
	NSArray *allValues = [attributesAndIndexes allValues];
	
	for (TKVariable *attrib in allValues) {
		NSString *attribName = [attrib name];
		if (attribName) [attributeKeys addObject:attribName];
	}
	
	glGetProgramiv(name, GL_ACTIVE_UNIFORMS, &count);
	
	GLsizei maxUniformLength = 0;
	
	glGetProgramiv(name, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxUniformLength);
	
	GLchar *uniformName = (GLchar *)malloc(maxUniformLength);
	
	for (GLint i = 0; i < count; i++) {
		GLsizei size = 0;
		GLenum type = 0;
		
		glGetActiveUniform(name, i, maxUniformLength, NULL, &size, &type, uniformName);
		
		NSString *uniformNameString = [NSString stringWithUTF8String:uniformName];
		
		TKVariable *uniform = [TKVariable variableWithName:uniformNameString variableType:TKVariableTypeUniform index:i size:size type:type];
		
		if (uniform) [uniformsAndIndexes setObject:uniform forKey:[NSNumber numberWithUnsignedInt:i]];
		
	}
	
	free(uniformName);
	
#if TK_DEBUG
	NSLog(@"[%@ %@] %@ uniformsAndIndexes == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName, uniformsAndIndexes);
#endif
	
	
	///////////////////////////////////////
	// Setup common program input points //
	///////////////////////////////////////
	
	
	GLint samplerLoc = glGetUniformLocation(name, "diffuseTexture");
	
	// Indicate that the diffuse texture will be bound to texture unit 0
	GLint unit = 0;
	glUniform1i(samplerLoc, unit);
	
	TKGetGLError();
	
	return YES;
}


- (void)useProgram {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	
	
//	if (generatedName == NO) [self generateName];
	
	if (!(self.isLinked && self.isValid)) {
		[self generateName];
	}
	glUseProgram(self.name);
}


- (NSArray *)attributeKeys {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (!(self.isLinked && self.isValid)) {
		[self generateName];
	}
	return attributeKeys;
}


- (NSArray *)uniformKeys {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (!(self.isLinked && self.isValid)) {
		[self generateName];
	}
	return [uniformsAndIndexes allValues];
}



- (void)setValue:(id)value forKeyPath:(NSString *)keyPath {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (!(self.isLinked && self.isValid)) {
		[self generateName];
	}
	
	BOOL isUniform = [keyPath hasPrefix:TKUniformPrefixKey];
	BOOL isAttrib = [keyPath hasPrefix:TKAttribPrefixKey];
	
	NSString *key = nil;
	TKVariable *variable = nil;
	
	if (isAttrib && !isUniform) {
		key = TKAttribKeyFromKeyPath(keyPath);
		NSArray *attribs = [attributesAndIndexes allValues];
		
		for (TKVariable *aVariable in attribs) {
			if ([[aVariable name] isEqual:key]) {
				variable = aVariable;
				break;
			}
		}
		
		NSParameterAssert(key != nil && variable != nil);
		
		GLenum type = [variable type];
		
		switch (type) {
				
			case GL_FLOAT : {
				
				break;
			}
				
			case GL_FLOAT_VEC2 : {
				TKVector2 vector = [(NSValue *)value vector2Value];
				glUniform2fv([variable index], 2, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_VEC3 : {
				TKVector3 vector = [(NSValue *)value vector3Value];
				glUniform3fv([variable index], 3, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_VEC4 : {
				TKVector4 vector = [(NSValue *)value vector4Value];
				glUniform4fv([variable index], 4, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_MAT2 : {
				TKMatrix2 matrix = [(NSValue *)value matrix2Value];
				glUniformMatrix2fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}
				
			case GL_FLOAT_MAT3 : {
				
				TKMatrix3 matrix = [(NSValue *)value matrix3Value];
				glUniformMatrix3fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}
				
			case GL_FLOAT_MAT4 : {
				
				TKMatrix4 matrix = [(NSValue *)value matrix4Value];
				glUniformMatrix4fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}

			default:
				break;
		}
		
		
		
	} else if (!isAttrib && isUniform) {
		key = TKUniformKeyFromKeyPath(keyPath);
		NSArray *uniforms = [uniformsAndIndexes allValues];
		
		for (TKVariable *aVariable in uniforms) {
			if ([[aVariable name] isEqual:key]) {
				variable = aVariable;
				break;
			}
		}
		
		NSParameterAssert(key != nil && variable != nil);
		
		GLenum type = [variable type];
		
		switch (type) {
				
			case GL_FLOAT : {
				
				break;
			}
				
			case GL_FLOAT_VEC2 : {
				TKVector2 vector = [(NSValue *)value vector2Value];
				glUniform2fv([variable index], 2, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_VEC3 : {
				TKVector3 vector = [(NSValue *)value vector3Value];
				glUniform3fv([variable index], 3, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_VEC4 : {
				TKVector4 vector = [(NSValue *)value vector4Value];
				glUniform4fv([variable index], 4, vector.v);
				
				break;
			}
				
				
			case GL_FLOAT_MAT2 : {
				TKMatrix2 matrix = [(NSValue *)value matrix2Value];
				glUniformMatrix2fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}
				
			case GL_FLOAT_MAT3 : {
				
				TKMatrix3 matrix = [(NSValue *)value matrix3Value];
				glUniformMatrix3fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}
				
			case GL_FLOAT_MAT4 : {
				
				TKMatrix4 matrix = [(NSValue *)value matrix4Value];
				glUniformMatrix4fv([variable index], 1, GL_FALSE, matrix.m);
				
				break;
			}
				
			default:
				break;
		}

		
		
	}
	
	
	
	
}



- (void)setValue:(id)value forAttribKey:(NSString *)key {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	[self setValue:value forKeyPath:TKKeyPathFromAttribKey(key)];
}


- (void)setValue:(id)value forUniformKey:(NSString *)key {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	[self setValue:value forKeyPath:TKKeyPathFromUniformKey(key)];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@,	", [super description]];
	[description appendFormat:@" - %@ -,	", displayName];
#if TK_DEBUG
	[description appendFormat:@"	attachedShaders == "];
	[description appendFormat:@"\n	%@\n", attachedShaders];
#endif
	[description appendFormat:@"	attributesAndIndexes == %@", attributesAndIndexes];
	[description appendFormat:@"	uniformsAndIndexes == %@", uniformsAndIndexes];
	return description;
}



@end



//- (void)deleteProgramWithName:(GLuint)aProgramName {
//#if TK_DEBUG
//	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
//#endif
//	
//	if (aProgramName == 0) return;
//	
//	glDeleteProgram(aProgramName);
//
//	GLsizei shaderNum;
//	GLsizei shaderCount;
//	
//	// Get the number of attached shaders
//	glGetProgramiv(aProgramName, GL_ATTACHED_SHADERS, &shaderCount);
//	
//	GLuint *shaders = (GLuint *)malloc(shaderCount * sizeof(GLuint));
//	
//	// Get the names of the shaders attached to the program
//	glGetAttachedShaders(aProgramName, shaderCount, &shaderCount, shaders);
//	
//	// Delete the shaders attached to the program
//	for (shaderNum = 0; shaderNum < shaderCount; shaderNum++) {
//		glDeleteShader(shaders[shaderNum]);
//	}
//	
//	free(shaders);
//	
//	// Delete the program
//	glDeleteProgram(aProgramName);
//	glUseProgram(0);
//}
