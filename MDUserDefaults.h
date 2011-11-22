//
//  MDUserDefaults.h
//  Font Finagler
//
//  Created by Mark Douma on 1/30/2008.
//  Copyright © 2008-2011 Mark Douma. All rights reserved.
//  


#import <Foundation/Foundation.h>

enum {
	MDUserDefaultsUserDomain = 1,
	MDUserDefaultsLocalDomain = 2,
	MDUserDefaultsLocalAndUserDomain = 3
};

typedef NSUInteger MDUserDefaultsDomain;


@interface MDUserDefaults : NSUserDefaults {
	
}
+ (MDUserDefaults *)standardUserDefaults;

- (void)setObject:(id)anObject forKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain;
- (id)objectForKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain;
- (void)removeObjectForKey:(NSString *)aKey forAppIdentifier:(NSString *)anIdentifier inDomain:(MDUserDefaultsDomain)aDomain;
@end



