//
//  FileReader.h
//  test
//
//  Created by Ahmad al-Moraly on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileReader : NSObject

- (id) initReaderWithFilePath:(NSString *)aPath;
- (id) initReaderWithFileURL:(NSURL *)fileURL;
- (id) initWriterWithFilePath:(NSString *)aPath;

- (NSString *) readLine;
- (NSString *) readTrimmedLine;

-(void)writeData:(NSString *)dataToWrite;

-(void)updateLine:(NSString *)line withNewValue:(NSString *)newLine;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString *line, BOOL *stop))block;
- (void) enumerateTrimmedLinesUsingBlock:(void(^)(NSString *trimmedLine, BOOL *stop))block;
#endif

@end

