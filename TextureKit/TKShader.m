//
//  TKShader.m
//  Texture Kit
//
//  Created by Mark Douma on 11/28/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKShader.h>
#import <TextureKit/TKShaderProgram.h>
//#import <TextureKit/TKModel.h>



#define TK_DEBUG 1


@interface TKShader ()

@property (nonatomic, assign, getter=isCompiled) BOOL compiled;

@end



NSString * const TKVertexShaderVSFileType			= @"vs";
NSString * const TKVertexShaderVSHFileType			= @"vsh";
NSString * const TKVertexShaderVERTFileType			= @"vert";
NSString * const TKVertexShaderVERTEXFileType		= @"vertex";

NSString * const TKFragmentShaderFSFileType			= @"fs";
NSString * const TKFragmentShaderFSHFileType		= @"fsh";
NSString * const TKFragmentShaderFRAGFileType		= @"frag";
NSString * const TKFragmentShaderFRAGMENTFileType	= @"fragment";


static NSArray *vertexShaderFileTypes	= nil;
static NSArray *fragmentShaderFileTypes = nil;

static GLfloat defaultShadingLanguageVersion = 0.0f;


static inline TKShaderType TKShaderTypeFromFileType(NSString *pathExtension) {
	pathExtension = [pathExtension lowercaseString];
	if ([vertexShaderFileTypes containsObject:pathExtension]) return TKVertexShaderType;
	else if ([fragmentShaderFileTypes containsObject:pathExtension]) return TKFragmentShaderType;
	return TKUnknownShaderType;
}



@implementation TKShader

@dynamic source;

@synthesize shaderType;

@synthesize displayName;

@synthesize shadingLanguageVersion;

@synthesize compiled;

@synthesize withNormals;
@synthesize withTexcoords;


+ (void)initialize {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	@synchronized(self) {
		if (vertexShaderFileTypes == nil) {
			vertexShaderFileTypes = [[NSArray alloc] initWithObjects:TKVertexShaderVSFileType, TKVertexShaderVSHFileType, TKVertexShaderVERTFileType, TKVertexShaderVERTEXFileType, nil];
			fragmentShaderFileTypes = [[NSArray alloc] initWithObjects:TKFragmentShaderFSFileType, TKFragmentShaderFSHFileType, TKFragmentShaderFRAGFileType, TKFragmentShaderFRAGMENTFileType, nil];
			
			// Determine if GLSL version 140 is supported by this context.
			//  We'll use this info to generate a GLSL shader source string
			//  with the proper version preprocessor string prepended
			GLfloat glLanguageVersion;
			
#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
			sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
			sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif
			
			defaultShadingLanguageVersion = glLanguageVersion;
			
		}
	}
}


+ (id)shaderWithContentsOfFile:(NSString *)filePath error:(NSError **)outError {
	return [[self class] shaderWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:outError];
}


+ (id)shaderWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	return [[(TKShader *)[[self class] alloc] initWithContentsOfURL:URL error:outError] autorelease];
}


+ (id)shaderWithSource:(NSString *)sourceString shaderType:(TKShaderType)aShaderType displayName:(NSString *)aDisplayName error:(NSError **)outError {
	return [[[[self class] alloc] initWithSource:sourceString shaderType:aShaderType displayName:aDisplayName error:outError] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)filePath error:(NSError **)outError {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	NSString *sourceString = [NSString stringWithContentsOfURL:URL usedEncoding:NULL error:outError];
	NSString *lastPathComponent = [[URL path] lastPathComponent];
	return [self initWithSource:sourceString shaderType:TKShaderTypeFromFileType([lastPathComponent pathExtension]) displayName:lastPathComponent error:outError];
}


- (id)initWithSource:(NSString *)sourceString shaderType:(TKShaderType)aShaderType displayName:(NSString *)aDisplayName error:(NSError **)outError {
	if ((self = [super init])) {
		source = [sourceString copy];
		shaderType = aShaderType;
		displayName = [aDisplayName retain];
		
		// Determine if GLSL version 140 is supported by this context.
		//  We'll use this info to generate a GLSL shader source string
		//  with the proper version preprocessor string prepended
		float glLanguageVersion;
		
#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "OpenGL ES GLSL ES %f", &glLanguageVersion);
#else
		sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);
#endif
		if ([[self class] defaultShadingLanguageVersion] != glLanguageVersion) {
			shadingLanguageVersion = [[self class] defaultShadingLanguageVersion];
		} else {
			shadingLanguageVersion = glLanguageVersion;
		}
	}
	return self;
}


+ (NSArray *)shadersNamed:(NSString *)filename {
	if (filename == nil) return nil;
	NSMutableArray *vertexPaths = [NSMutableArray array];
	NSMutableArray *fragmentPaths = [NSMutableArray array];
	
	for (NSString *fileType in vertexShaderFileTypes) {
		NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:fileType];
		if (filePath) [vertexPaths addObject:filePath];
	}
	
	for (NSString *fileType in fragmentShaderFileTypes) {
		NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:fileType];
		if (filePath) [fragmentPaths addObject:filePath];
	}
	
	if ([vertexPaths count] == 0 && [fragmentPaths count] == 0) return nil;
	
	NSMutableArray *shaders = [NSMutableArray array];
	
	for (NSString *filePath in vertexPaths) {
		NSError *error = nil;
		TKShader *shader = [TKShader shaderWithContentsOfFile:filePath error:&error];
		if (shader) [shaders addObject:shader];
	}
	
	for (NSString *filePath in fragmentPaths) {
		NSError *error = nil;
		TKShader *shader = [TKShader shaderWithContentsOfFile:filePath error:&error];
		if (shader) [shaders addObject:shader];
	}
	
	return [[shaders copy] autorelease];
}


- (void)dealloc {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	glDeleteShader(name);
	[source release];
	[displayName release];
	[super dealloc];
}


+ (GLfloat)defaultShadingLanguageVersion {
	GLfloat rDefaultShadingLanguageVersion = 0.0;
	@synchronized(self) {
		rDefaultShadingLanguageVersion = defaultShadingLanguageVersion;
	}
	return rDefaultShadingLanguageVersion;
}


+ (void)setDefaultShadingLanguageVersion:(GLfloat)version {
	@synchronized(self) {
		defaultShadingLanguageVersion = version;
	}
}


- (NSString *)source {
	return source;
}


- (void)setSource:(NSString *)aSource {
#if TK_DEBUG		
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (aSource != source) {
		[source release];
		source = [aSource copy];
		[self setCompiled:NO];
		generatedName = NO;
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
	
	NSString *outputCompileLog = nil;
	if (![self compileWithLog:&outputCompileLog]) {
		
	}
	
	generatedName = YES;
	[nameLock unlock];
}



- (BOOL)compileWithLog:(NSString **)outCompileLog {
#if TK_DEBUG
	NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName);
#endif
	if (self.isCompiled) return YES;
	
	if (source == nil) return NO;
	
	// GL_SHADING_LANGUAGE_VERSION returns the version standard version form
	//  with decimals, but the GLSL version preprocessor directive simply
	//  uses integers (thus 1.10 should 110 and 1.40 should be 140, etc.)
	//  We multiply the floating point number by 100 to get a proper
	//  number for the GLSL preprocessor directive
	
	GLuint version = 100 * shadingLanguageVersion;
	
	
	// Prepend our shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	
	NSString *sourceWithVersion =  [NSString stringWithFormat:@"#version %u\n%@", version, source];
	
	
	name = glCreateShader((shaderType == TKVertexShaderType ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER));
	
	const char *shaderSourceCString = [sourceWithVersion UTF8String];
	
	glShaderSource(name, 1, (const GLchar **)&shaderSourceCString, NULL);
	
//	glShaderSource(name, 1, (const GLchar **)shaderSourceCString, NULL);
	glCompileShader(name);
	
	GLint logLength, status;
	
	glGetShaderiv(name, GL_INFO_LOG_LENGTH, &logLength);
	
	if (logLength) {
		GLchar *log = (GLchar *)malloc(logLength);
		glGetShaderInfoLog(name, logLength, &logLength, log);
		NSLog(@"[%@ %@] %@ - %@ Shader compile log:%s\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName,
										(shaderType == TKVertexShaderType ? @"Vertex" : @"Fragment"), log);
		
		if (outCompileLog) *outCompileLog = [NSString stringWithUTF8String:log];
		free(log);
	}
	
	glGetShaderiv(name, GL_COMPILE_STATUS, &status);
	
	if (status == 0) {
		NSLog(@"[%@ %@] %@ - Failed to compile vtx shader:\n%@\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd), displayName, source);
		return NO;
	}
	
	TKGetGLError();
	
	[self setCompiled:YES];
	
	return YES;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@,	", [super description]];
	[description appendFormat:@" - %@ -,	", displayName];
#if TK_DEBUG
	[description appendFormat:@"	source == "];
	[description appendFormat:@"\n	%@\n", source];
#endif
	return description;
}



@end


