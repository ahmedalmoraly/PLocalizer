//
//  FileReader.m
//  test
//
//  Created by Ahmad al-Moraly on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileReader.h"

@interface NSData (FileReader)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind;

@end

@implementation NSData (FileReader)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind {
    
    const void * bytes = [self bytes];
    NSUInteger length = [self length];
    
    const void * searchBytes = [dataToFind bytes];
    NSUInteger searchLength = [dataToFind length];
    NSUInteger searchIndex = 0;
    
    NSRange foundRange = {NSNotFound, searchLength};
    for (NSUInteger index = 0; index < length; index++) {
        if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex]) {
            //the current character matches
            if (foundRange.location == NSNotFound) {
                foundRange.location = index;
            }
            searchIndex++;
            if (searchIndex >= searchLength) { return foundRange; }
        } else {
            searchIndex = 0;
            foundRange.location = NSNotFound;
        }
    }
    return foundRange;
}

@end

@interface FileReader ()

@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSFileHandle *fileHandle;
@property (unsafe_unretained, nonatomic) unsigned long long currentOffset;
@property (unsafe_unretained, nonatomic) unsigned long long totalFileLength;

@property (nonatomic, copy) NSString * lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;
@end

@implementation FileReader
@synthesize lineDelimiter = _lineDelimiter;
@synthesize chunkSize = _chunckSize;

@synthesize filePath = _filePath;
@synthesize fileHandle = _fileHandle;
@synthesize currentOffset = _currentOffset;
@synthesize totalFileLength = _totalFileLength;

-(id)initReaderWithFileURL:(NSURL *)fileURL
{
    if (self = [super init]) {
        self.fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileURL error:nil];
        if (self.fileHandle == nil) {
            return nil;
        }
        
        self.lineDelimiter = [NSString stringWithString:@"\n"];
        
        self.filePath = fileURL.absoluteString;
        self.currentOffset = 0ULL;
        self.chunkSize = 10;
        [self.fileHandle seekToEndOfFile];
        self.totalFileLength = [self.fileHandle offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    return self;   
}

- (id) initReaderWithFilePath:(NSString *)aPath {
    
    if (self = [super init]) {
        self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
        if (self.fileHandle == nil) {
            return nil;
        }
        
        self.lineDelimiter = [NSString stringWithString:@"\n"];

        self.filePath = aPath;
        self.currentOffset = 0ULL;
        self.chunkSize = 10;
        [self.fileHandle seekToEndOfFile];
        self.totalFileLength = [self.fileHandle offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    return self;
}

-(id)initWriterWithFilePath:(NSString *)aPath {
    if (self = [super init]) {
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:aPath];
        if (self.fileHandle == nil) {
            return nil;
        }
        self.lineDelimiter = [NSString stringWithString:@"\n"];
        
        self.filePath = aPath;
        self.currentOffset = 0ULL;
        self.chunkSize = 10;

    }
    return self;
}

-(void)writeData:(NSString *)dataToWrite {
    
    [self.fileHandle writeData:[dataToWrite dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *) readLine {
    if (self.currentOffset >= self.totalFileLength) { return nil; }
    
    NSData * newLineData = [self.lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    [self.fileHandle seekToFileOffset:self.currentOffset];
    
    NSMutableData * currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;
    
    @autoreleasepool {
        while (shouldReadMore) {
            if (self.currentOffset >= self.totalFileLength) { break; }
            
            NSData *chunk = [self.fileHandle readDataOfLength:self.chunkSize];
            
            NSRange newLineRange = [chunk rangeOfData_dd:newLineData];
            
            if (newLineRange.location != NSNotFound) {
                
                //include the length so we can include the delimiter in the string
                chunk = [chunk subdataWithRange:NSMakeRange(0, newLineRange.location+[newLineData length])];
                shouldReadMore = NO;
            }
            
            [currentData appendData:chunk];
            self.currentOffset += [chunk length];
        }

    }
    
    NSString * line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];

    return line;
}

- (NSString *) readTrimmedLine {
    return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(void)updateLine:(NSString *)line withNewValue:(NSString *)newLine
{

}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block {
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine])) {
        block(line, &stop);
    }
    [self.fileHandle closeFile];
}

-(void)enumerateTrimmedLinesUsingBlock:(void (^)(NSString *, BOOL *))block
{
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readTrimmedLine])) {
        block(line, &stop);
    }
    
    [self.fileHandle closeFile];
    
}
#endif

@end