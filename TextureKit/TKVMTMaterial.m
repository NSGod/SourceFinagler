//
//  TKVMTMaterial.m
//  Texture Kit
//
//  Created by Mark Douma on 1/17/2011.
//  Copyright (c) 2010-2012 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TKVMTMaterial.h>
#import <Cocoa/Cocoa.h>
#import <TextureKit/TKVMTNode.h>


#define TK_DEBUG 1

@interface TKVMTMaterial (TKPrivate)

- (BOOL)parseData:(NSData *)aData error:(NSError **)outError;

+ (void)raiseExceptionWithName:(NSString *)name description:(NSString *)description;

@end



enum {
	TKTokenEOF			= 0,	// No more tokens to read.
	TKTokenNewline,				// Token is a newline (\n).
	TKTokenWhitespace,			// Token is any whitespace other than a newline.
	TKTokenForwardSlash,		// Token is a forward slash (/).
	TKTokenQuote,				// Token is a quote (").
	TKTokenOpenBrace,			// Token is an open brace ({).
	TKTokenCloseBrace,			// Token is a close brace (}).
	TKTokenChar,				// Token is a char (any char).  Use GetChar().
	TKTokenString,				// Token is a string.  Use GetString().
	TKTokenQuotedString,		
	TKTokenSpecial				// Token is a specified special char.
};
typedef NSUInteger TKTokenType;


@interface TKToken : NSObject <NSCopying> {
	NSString			*stringValue;
	TKTokenType			type;
	unichar				charValue;
	
}

- (id)initWithType:(TKTokenType)aType stringValue:(NSString *)aString char:(unichar)aChar;

+ (id)tokenWithType:(TKTokenType)aType;

+ (id)tokenWithType:(TKTokenType)aType char:(unichar)aChar;

+ (id)charTokenWithChar:(unichar)aCharValue;

+ (id)stringTokenWithStringValue:(NSString *)aString isQuoted:(BOOL)isQuoted;


@property (nonatomic, retain) NSString *stringValue;
@property (nonatomic, assign) TKTokenType type;
@property (nonatomic, assign) unichar charValue;

- (void)toSpecial:(NSString *)aSpecialString;


@end


@implementation TKToken

@synthesize stringValue;
@synthesize type;
@synthesize charValue;



+ (id)tokenWithType:(TKTokenType)aType {
	return [[[[self class] alloc] initWithType:aType stringValue:nil char:'\0'] autorelease];
}

+ (id)tokenWithType:(TKTokenType)aType char:(unichar)aChar {
	return [[[[self class] alloc] initWithType:aType stringValue:nil char:aChar] autorelease];
}


+ (id)charTokenWithChar:(unichar)aCharValue {
	return [[[[self class] alloc] initWithType:TKTokenChar stringValue:nil char:aCharValue] autorelease];
}


+ (id)stringTokenWithStringValue:(NSString *)aString isQuoted:(BOOL)isQuoted {
	return [[[[self class] alloc] initWithType:(isQuoted ? TKTokenQuotedString : TKTokenString) stringValue:aString char:'\0'] autorelease];
}


- (id)initWithType:(TKTokenType)aType stringValue:(NSString *)aString char:(unichar)aChar {
	if ((self = [super init])) {
		type = aType;
		stringValue = [aString retain];
		charValue = aChar;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	id copy = [[[self class] alloc] initWithType:type stringValue:stringValue char:charValue];
	return copy;
}


- (void)dealloc {
    [stringValue release];
    [super dealloc];
}

// Convert the current token to a special token.
// We need to do this because the tokenizer reads ahead and doesn't
// know if the requested token will be special until after the fact.
- (void)toSpecial:(NSString *)aSpecialString {
	if (type == TKTokenEOF) return;
	
	for (NSUInteger i = 0; i < [aSpecialString length]; i++) {
		if (charValue == [aSpecialString characterAtIndex:i]) {
			type = TKTokenSpecial;
			return;
		}
	}
	
	type = TKTokenChar;
}

@end


// Tokenizes single byte tokens.
@interface TKByteTokenizer : NSObject {
	NSData				*data;
	NSUInteger			currentDataIndex;
	
	TKToken				*currentToken;
	TKToken				*nextToken;
	NSUInteger			lineIndex;
	
}

+ (id)byteTokenizerWithData:(NSData *)aData;
- (id)initWithData:(NSData *)aData;


@property (nonatomic, retain) TKToken *currentToken;
@property (nonatomic, retain) TKToken *nextToken;
@property (nonatomic, assign) NSUInteger lineIndex;

//	equiv of CByteTokenizer::GetNextToken()
- (void)scanToString:(NSString *)aString;

// equiv of CByteTokenizer::Next()
// "Get the current token and return the next one."
- (TKToken *)nextTokenWithString:(NSString *)aString;


@end




@implementation TKByteTokenizer

@synthesize currentToken;
@synthesize nextToken;
@synthesize lineIndex;

+ (id)byteTokenizerWithData:(NSData *)aData {
	return [[[[self class] alloc] initWithData:aData] autorelease];
}


- (id)initWithData:(NSData *)aData {
	if ((self = [super init])) {
		data = [aData retain];
		[self scanToString:nil];
	}
	return self;
}


- (void)dealloc {
	[data release];
    [currentToken release];
	[nextToken release];
    [super dealloc];
}


- (void)scanToString:(NSString *)aString {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (currentDataIndex == [data length]) {
		self.nextToken = [TKToken tokenWithType:TKTokenEOF];
		return;
	}
	
	char nextChar = 0;
	
	[data getBytes:&nextChar range:NSMakeRange(currentDataIndex, sizeof(char))];
	
	currentDataIndex += sizeof(char);
	
	// Keep track of the line number.
	if (nextChar == '\n') lineIndex++;
	
	// If a special char was specified, only return TOKEN_CHAR tokens
	// unless the special char was found in which case return a
	// TOKEN_SPECIAL.
	
	if (aString) {
		for (NSUInteger i = 0; i < [aString length]; i++) {
			if (nextChar == [aString characterAtIndex:i]) {
				self.nextToken = [TKToken tokenWithType:TKTokenSpecial char:[aString characterAtIndex:i]];
				return;
			}
		}
		
		self.nextToken = [TKToken charTokenWithChar:nextChar];
		return;
	}
	
	if (nextChar == '\r' || nextChar == '\n') {
		self.nextToken = [TKToken tokenWithType:TKTokenNewline char:nextChar];
		
	} else if (isspace(nextChar)) {
		self.nextToken = [TKToken tokenWithType:TKTokenWhitespace char:nextChar];
		
	} else if (nextChar == '/') {
		self.nextToken = [TKToken tokenWithType:TKTokenForwardSlash char:nextChar];
		
	} else if (nextChar == '\"') {
		self.nextToken = [TKToken tokenWithType:TKTokenQuote char:nextChar];
		
	} else if (nextChar == '{') {
		self.nextToken = [TKToken tokenWithType:TKTokenOpenBrace char:nextChar];
		
	} else if (nextChar == '}') {
		self.nextToken = [TKToken tokenWithType:TKTokenCloseBrace char:nextChar];
		
	} else {
		self.nextToken = [TKToken charTokenWithChar:nextChar];
		
	}
}


// equiv of CByteTokenizer::Next()
// "Get the current token and return the next one."
- (TKToken *)nextTokenWithString:(NSString *)aString {
	self.currentToken = nextToken;
	self.nextToken = nil;
	
	if (aString && currentToken) {
		[currentToken toSpecial:aString];
	}
	
	[self scanToString:nil];
	return currentToken;
}


@end


// Tokenizes multi byte tokens.
@interface TKTokenizer : NSObject {
	TKByteTokenizer		*byteTokenizer;
	TKToken				*currentToken;
	TKToken				*nextToken;
}

+ (id)tokenizerWithByteTokenizer:(TKByteTokenizer *)aByteTokenizer;
- (id)initWithByteTokenizer:(TKByteTokenizer *)aByteTokenizer;

@property (nonatomic, retain) TKByteTokenizer *byteTokenizer;
@property (nonatomic, retain) TKToken *currentToken;
@property (nonatomic, retain) TKToken *nextToken;

//	equiv of CTokenizer::GetNextToken()
- (void)scan;


//  equiv of CTokenizer::Next()
- (TKToken *)next;

//  equiv of CTokenizer::Peek()
- (TKToken *)peek;

//  equiv of CTokenizer::GetLine()
- (NSUInteger)lineIndex;


@end



// Tokenizes multi byte tokens.
@implementation TKTokenizer

@synthesize byteTokenizer;
@synthesize currentToken;
@synthesize nextToken;


+ (id)tokenizerWithByteTokenizer:(TKByteTokenizer *)aByteTokenizer {
	return [[[[self class] alloc] initWithByteTokenizer:aByteTokenizer] autorelease];
}


- (id)initWithByteTokenizer:(TKByteTokenizer *)aByteTokenizer {
	if ((self = [super init])) {
		byteTokenizer = [aByteTokenizer retain];
		[self scan];
	}
	return self;
}


- (void)dealloc {
    [byteTokenizer release];
	[currentToken release];
	[nextToken release];
    [super dealloc];
}


//	equiv of CTokenizer::GetNextToken()
- (void)scan {
	TKToken *token = [byteTokenizer nextTokenWithString:nil];
	
	// Consume all whitespace.
	
	while (token.type == TKTokenWhitespace) {
		token = [byteTokenizer nextTokenWithString:nil];
	}
	
//	NSUInteger index = 0;
	NSMutableString *mString = [NSMutableString string];
	
	TKTokenType tokenType = token.type;
	
	switch (tokenType) {
			
		// Comment (these are removed for the parser).
		case TKTokenForwardSlash : {
			token = [byteTokenizer nextTokenWithString:nil];
			
			if (token.type != TKTokenForwardSlash) {
				[TKVMTMaterial raiseExceptionWithName:@"expected comment string"
										  description:@"expected comment string"];
				
			}
			
			do {
				token = [byteTokenizer nextTokenWithString:@"\n"];
			} while (token.type == TKTokenChar);
			
			
			if (token.type == TKTokenEOF) {
				self.nextToken = [TKToken tokenWithType:TKTokenEOF];
			} else {
				self.nextToken = [TKToken tokenWithType:TKTokenNewline];
			}
			
			break;
			
			
		}
			
		// Quoted string.
		case TKTokenQuote : {
			
			while (YES) {
				token = [byteTokenizer nextTokenWithString:@"\""];
				
				if (token.type != TKTokenChar) break;
				
				if (token.charValue == '\r' || token.type == '\n') {
					[TKVMTMaterial raiseExceptionWithName:@"newline in string"
											  description:@"newline in string"];
					
				}
				
				[mString appendFormat:@"%C", token.charValue];
			}
			
			if (token.type != TKTokenSpecial) {
				[TKVMTMaterial raiseExceptionWithName:@"expected closing quote"
										  description:@"expected closing quote"];
				
			} else {
				self.nextToken = [TKToken stringTokenWithStringValue:mString isQuoted:YES];
			}
			
			break;
		}
			
			
			
		// Unquoted string.
		case TKTokenChar : {
			
			[mString appendFormat:@"%C", token.charValue];
			
			while ([byteTokenizer peek].type == TKTokenChar) {
				token = [byteTokenizer nextTokenWithString:nil];
				
				[mString appendFormat:@"%C", token.charValue];
				
			}
			
			self.nextToken = [TKToken stringTokenWithStringValue:mString isQuoted:NO];
			
			break;
		}
			
		// Let these byte tokens "pass through".
		case TKTokenEOF :
		case TKTokenNewline :
		case TKTokenOpenBrace :
		case TKTokenCloseBrace : {
			
			self.nextToken = [[token copy] autorelease];
			
			break;
		}
			
		// The parser doesn't care about anything else.
		default : {
			
			[TKVMTMaterial raiseExceptionWithName:@"unexpected token"
									  description:@"unexpected token"];
			break;
		}
	}
	
	
}


//  equiv of CTokenizer::Next()

- (TKToken *)next {
	self.currentToken = nextToken;
	
	self.nextToken = nil;
	
	[self scan];
	
	return currentToken;
}

- (TKToken *)peek {
	return nextToken;
}

- (NSUInteger)lineIndex {
	return byteTokenizer.lineIndex;
}


@end


// Uses multi byte tokenizer to process the file.
@interface TKVMTParser : NSObject {
	TKTokenizer			*tokenizer;
	
}
+ (id)parserWithTokenizer:(TKTokenizer *)aTokenizer;
- (id)initWithTokenizer:(TKTokenizer *)aTokenizer;

@property (nonatomic, retain) TKTokenizer *tokenizer;

//	equivalent to CParser::Parse(void)
- (TKVMTNode *)rootNode;


//	equivalent to CParser::Parse(CVMTGroupNode *Group)
- (void)parseGroupNode:(TKVMTNode *)groupNode;

@end




@implementation TKVMTParser

@synthesize tokenizer;

+ (id)parserWithTokenizer:(TKTokenizer *)aTokenizer {
	return [[[[self class] alloc] initWithTokenizer:aTokenizer] autorelease];
}


- (id)initWithTokenizer:(TKTokenizer *)aTokenizer {
	if ((self = [super init])) {
		tokenizer = [aTokenizer retain];
	}
	return self;
}

- (void)dealloc {
	[tokenizer release];
	[super dealloc];
}


- (TKVMTNode *)rootNode {
	TKVMTNode *groupNode = nil;
	
	TKToken *token = [tokenizer next];
	
	// Consume all newlines.
	while (token.type == TKTokenNewline) {
		token = [tokenizer next];
	}
	
	TKTokenType tokenType = token.type;
	
	if (tokenType == TKTokenString || tokenType == TKTokenQuotedString) {
		groupNode = [TKVMTNode groupNodeWithName:[token stringValue]];
	} else {
		[TKVMTMaterial raiseExceptionWithName:@"expected shader name" description:@"expected shader name"];
	}
	
	// We *may* have a group, parse it.
	[self parseGroupNode:groupNode];
	
	while (YES) {
		
		// Consume all newlines.
		while ([tokenizer peek].type == TKTokenNewline) {
			token = [tokenizer next];
		}
		
		TKToken *peek = [tokenizer peek];
		
		if (peek.type == TKTokenEOF) {
			
			break;
			
		} else if (peek.type == TKTokenOpenBrace) {
			TKVMTNode *nextGroup = nil;
			
			@try {
				nextGroup = [TKVMTNode groupNodeWithName:@""];
				[self parseGroupNode:nextGroup];
				
			}
			@catch (NSException *exception) {
				
				
			}
			
			for (NSUInteger i = 0; i < [nextGroup countOfChildren]; i++) {
				[groupNode addChild:[nextGroup childAtIndex:i]];
			}
			
		} else {
			[TKVMTMaterial raiseExceptionWithName:@"expected end of file" description:@"expected end of file"];
		}
	}
	return groupNode;
}


//	Parse a group starting at the first brace and ending at the last.
- (void)parseGroupNode:(TKVMTNode *)groupNode {
	TKToken *token = [tokenizer next];
	
	// Consume all newlines.
	while (token.type == TKTokenNewline) {
		token = [tokenizer next];
	}
	
	TKTokenType tokenType = token.type;
	
	if (tokenType != TKTokenOpenBrace) {
		[TKVMTMaterial raiseExceptionWithName:@"expected open brace" description:@"expected open brace"];
	}
	
	// Parse remaining tokens.
	while (YES) {
		token = [tokenizer next];
		
		while (token.type == TKTokenNewline) {
			token = [tokenizer next];
		}
		
		tokenType = token.type;
		
		// If we have an end brace, we found the end of the group.
		if (tokenType == TKTokenCloseBrace || tokenType == TKTokenEOF) {
			return;
		}
		
		// If we have a string we could have a pair or nested group.
		if (tokenType == TKTokenString || tokenType == TKTokenQuotedString) {
			TKToken *peek = [tokenizer peek];
			
			if (peek.type == TKTokenString || peek.type == TKTokenQuotedString) {
				// We have a pair.
				
				if (peek.type == TKTokenQuotedString) {
					[groupNode addChild:[TKVMTNode stringNodeWithName:token.stringValue stringValue:peek.stringValue]];
					
					token = [tokenizer next];
					
				} else {
					
					NSString *name = [token stringValue];
					
					NSMutableString *mString = [NSMutableString string];
					
					// Some materials contain properties such as '"$envmaptint" .1 .1 .1', we need to read
					// the .1's as strings and concat them (way to be consistent Valve).
					
					while ([tokenizer peek].type == TKTokenString) {
						token = [tokenizer next];
						
						if (![mString isEqualToString:@""]) {
							[mString appendString:@" "];
						}
						
						[mString appendString:[token stringValue]]; 
					}
					
#if TK_DEBUG
					NSLog(@"[%@ %@] mString == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mString);
#endif
					NSInteger iTest = 0;
					float fTest = 0.0;
					
					NSScanner *scanner = [NSScanner scannerWithString:mString];
					
					if ([scanner scanInteger:&iTest]) {
						// We can interpet the string as an integer, assume it is one.
						
						[groupNode addChild:[TKVMTNode integerNodeWithName:name integerValue:iTest]];
						
					} else if ([scanner scanFloat:&fTest]) {
						// We can interpet the string as an single, assume it is one.
						
						[groupNode addChild:[TKVMTNode floatNodeWithName:name floatValue:fTest]];
						
					} else {
						// The string must be a string...
						
						[groupNode addChild:[TKVMTNode stringNodeWithName:name stringValue:mString]];
					}
				}
				
				BOOL needNewline = (token.type != TKTokenQuotedString);
				if (needNewline) {
					token = [tokenizer next];
					
					if (token.type != TKTokenNewline) {
						[TKVMTMaterial raiseExceptionWithName:@"expected newline"
												  description:@"expected newline"];
						
					}
					
				}
				
			} else if (peek.type == TKTokenNewline || peek.type == TKTokenOpenBrace) {
				
				// We have a nested group, parse it.
				TKVMTNode *nestedGroupNode = [TKVMTNode groupNodeWithName:token.stringValue];
				[groupNode addChild:nestedGroupNode];
				
				[self parseGroupNode:nestedGroupNode];
				
			} else {
				
				[TKVMTMaterial raiseExceptionWithName:@"expected open brace or attribute value"
										  description:@"expected open brace or attribute value"];
			}
			
		} else {
			[TKVMTMaterial raiseExceptionWithName:@"expected close brace or group name or attribute name"
									  description:@"expected close brace or group name or attribute name"];
		}
	}
	
	
}



@end



@implementation TKVMTMaterial

@synthesize rootNode;

+ (void)raiseExceptionWithName:(NSString *)name description:(NSString *)description {
	@throw [NSException exceptionWithName:name reason:description userInfo:nil];
}

+ (id)materialWithContentsOfFile:(NSString *)aPath error:(NSError **)outError {
	return [[[[self class] alloc] initWithContentsOfFile:aPath error:outError] autorelease];
}


+ (id)materialWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	return [[(TKVMTMaterial *)[[self class] alloc] initWithContentsOfURL:URL error:outError] autorelease];
}


+ (id)materialWithData:(NSData *)aData error:(NSError **)outError {
	return [[[[self class] alloc] initWithData:aData error:outError] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)aPath error:(NSError **)outError {
	return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath] error:outError];
}


- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)outError {
	return [self initWithData:[NSData dataWithContentsOfURL:URL] error:outError];
}


- (id)initWithData:(NSData *)aData error:(NSError **)outError {
	NSParameterAssert(aData != nil);
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if ((self = [super init])) {
		if (outError) *outError = nil;
		
		@try {
			if (![self parseData:aData error:outError]) {
				
			}
		}
		
		@catch (NSException *exception) {
			NSLog(@"[%@ %@] Error while parsing VMT file (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), exception);
			[self release];
			return nil;
			
		}
//		@finally {
//			
//			
//		}
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return nil;
}

- (BOOL)parseData:(NSData *)aData error:(NSError **)outError {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	TKVMTParser *parser = [TKVMTParser parserWithTokenizer:[TKTokenizer tokenizerWithByteTokenizer:[TKByteTokenizer byteTokenizerWithData:aData]]];
	
	rootNode = [[parser rootNode] retain];
	
	return rootNode != nil;
}



- (NSDictionary *)dictionaryRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return nil;
}


- (NSString *)stringRepresentation {
#if TK_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	return nil;
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\n", [super description]];
	[description appendFormat:@"	rootNode == %@", rootNode];
	return description;
}

@end




