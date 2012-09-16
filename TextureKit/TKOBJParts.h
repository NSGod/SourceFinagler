//
//  TKOBJParts.h
//  Texture Kit
//
//  Created by Mark Douma on 12/8/2011.
//  Copyright (c) 2011 Mark Douma LLC. All rights reserved.
//

#import <TextureKit/TextureKitDefines.h>
#import <TextureKit/TKOBJModel.h>
#import <TextureKit/TKMath.h>


TEXTUREKIT_EXTERN NSString * const TKOBJVertexKey;				// v
TEXTUREKIT_EXTERN NSString * const TKOBJTextureVertexKey;		// vt
TEXTUREKIT_EXTERN NSString * const TKOBJVertexNormalKey;		// vn


@interface TKOBJVertex : NSObject {
	TKVector3		vertex;
}

+ (id)vertexWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

@property (readonly, nonatomic, assign) TKVector3 vertex;

+ (NSData *)dataWithVerticesInArray:(NSArray *)vertices;


@end


@interface TKOBJTextureVertex : NSObject {
	TKVector2		textureVertex;
}

+ (id)textureVertexWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

@property (readonly, nonatomic, assign) TKVector2 textureVertex;

+ (NSData *)dataWithTextureVerticesInArray:(NSArray *)textureVertices;

@end



@interface TKOBJVertexNormal : NSObject {
	TKVector3		vertexNormal;
}

+ (id)vertexNormalWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

@property (readonly, nonatomic, assign) TKVector3 vertexNormal;

+ (NSData *)dataWithVertexNormalsInArray:(NSArray *)vertexNormals;

@end


@interface TKOBJTriplet : NSObject {
	TKOBJVertex					*vertex;
	TKOBJTextureVertex			*textureVertex;
	TKOBJVertexNormal			*vertexNormal;
}

+ (id)tripletWithVertex:(TKOBJVertex *)aVertex textureVertex:(TKOBJTextureVertex *)aTextureVertex vertexNormal:(TKOBJVertexNormal *)aVertexNormal;
- (id)initWithVertex:(TKOBJVertex *)aVertex textureVertex:(TKOBJTextureVertex *)aTextureVertex vertexNormal:(TKOBJVertexNormal *)aVertexNormal;

@property (nonatomic, retain) TKOBJVertex *vertex;
@property (nonatomic, retain) TKOBJTextureVertex *textureVertex;
@property (nonatomic, retain) TKOBJVertexNormal *vertexNormal;

@end




@interface TKOBJFace : NSObject {
	
}


@end





