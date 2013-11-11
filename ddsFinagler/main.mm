//
//  main.m
//  ddsFinagler
//
//  Created by Mark Douma on 11/1/2012.
//
//

#import <Foundation/Foundation.h>

#import <NVImage/DirectDrawSurface.h>

//#import "NVImage.h"


using namespace nv;



int main(int argc, const char * argv[]) {

	@autoreleasepool {
		
		NSArray *arguments = [[NSProcessInfo processInfo] arguments];
		if (arguments.count == 1) exit(EXIT_FAILURE);
		
		
		NSArray *filePaths = [arguments subarrayWithRange:NSMakeRange(1, arguments.count - 1)];
		
		for (NSString *filePath in filePaths) {
			DirectDrawSurface *dds = new DirectDrawSurface([filePath fileSystemRepresentation]);
			
			NSLog(@"ddsInfo() for %@", filePath);
			
			dds->printInfo();
			
			printf("\n\n\n");
		}
	}
    return 0;
}

