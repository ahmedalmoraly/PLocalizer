//
//  FilePathEntity.h
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilePathEntity : NSObject 

@property (strong) NSURL *fileURL;
@property (strong, readonly) NSString *title;

+ (FilePathEntity *)entityForURL:(NSURL *)url;

- (id)initWithFileURL:(NSURL *)fileURL;

@end


@interface DirectoryEntity : FilePathEntity

@property (strong) NSMutableArray *files;


@end