//
//  FilePathEntity.m
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "FilePathEntity.h"

@implementation FilePathEntity
@synthesize fileURL = _fileURL;
@dynamic title;

+(FilePathEntity *)entityForURL:(NSURL *)url
{
    NSString *typeIdentifier;
    if ([url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL]) 
    {
        if ([typeIdentifier isEqualToString:(NSString *)kUTTypeObjectiveCSource]) 
        {
            return [[FilePathEntity alloc] initWithFileURL:url];
        } 
        else if ([typeIdentifier isEqualToString:(NSString *)kUTTypeFolder]) 
        {
            return [[DirectoryEntity alloc] initWithFileURL:url];
        } 
    }
    return nil;
}

-(id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    self.fileURL = fileURL;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    id result = [[[self class] alloc] initWithFileURL:self.fileURL];
    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ : %@", [super description], self.title];
}

- (NSString *)title {
    NSString *result;
    if ([self.fileURL getResourceValue:&result forKey:NSURLLocalizedNameKey error:NULL]) {
        return result;
    }
    return nil;
}


@end

@interface DirectoryEntity ()

-(void)reloadFiles;

@end

@implementation DirectoryEntity
@synthesize files = _files;

-(id)initWithFileURL:(NSURL *)fileURL
{
    self = [super initWithFileURL:fileURL];
    [self reloadFiles];
    return self;
}

-(void)reloadFiles
{
    dispatch_queue_t queue = dispatch_queue_create("open.file.async", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.fileURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLLocalizedNameKey, nil] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:&error];
        NSMutableArray *newChildren = [NSMutableArray arrayWithCapacity:urls.count];
        
        [urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            NSString *typeIdentifier;
            if ([url getResourceValue:&typeIdentifier forKey:NSURLTypeIdentifierKey error:NULL]) 
            {
                FilePathEntity *entity = [FilePathEntity entityForURL:url];
                if (entity) {
                    [newChildren addObject:entity];
                }
            }
        }];
        self.files = newChildren;
    });
    
}


@end