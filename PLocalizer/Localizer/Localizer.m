//
//  Localizer.m
//  PLocalizer
//
//  Created by Ali Amin on 7/3/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "Localizer.h"
#import "FileReader.h"

@interface Localizer ()


-(BOOL)shouldLocalizeStatement:(NSString *)statement;
-(BOOL)shouldLocalizeString:(NSString *)string;

-(NSArray *)getAllStringsInStatement:(NSString *)statement;
@end

@implementation Localizer

+(Localizer *)defaultLocalizer
{
    static Localizer *_defaultLocalizer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultLocalizer = [[self alloc] init];
    });
    return _defaultLocalizer;
}

-(NSArray *)searchForStringsInDirectory:(NSString *)path
{
    NSMutableArray *stringFiles = [NSMutableArray array];
    
    NSError *error;
    
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    for (NSString *filePath in array) {
        // create the path
        NSString *wholePath = [path stringByAppendingPathComponent:filePath];
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:wholePath isDirectory:&isDirectory];
        
        if (isDirectory) {
            // loop again
            [self searchForStringsInDirectory:wholePath];
        }
        else {
            if (![filePath.pathExtension isEqualToString:@"m"]) {
                continue;
            }
                // NSDictionary *localizedStrings = [self localizeStringsInFilesAtPath:wholePath];
            //if (localizedStrings.count) {
            //    [stringFiles addObject:[NSDictionary dictionaryWithObject:localizedStrings forKey:filePath]];
            //}
        }
    }

    
    return stringFiles;
}

-(NSDictionary *)localizeStringsInFilesAtPath:(NSURL *)path
{

    FileReader *fileReader = [[FileReader alloc] initReaderWithFileURL:path];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [fileReader enumerateTrimmedLinesUsingBlock:^(NSString *trimmedLine, BOOL *stop) {
        
        if ([self shouldLocalizeStatement:trimmedLine])
        {
            NSArray *strings = [self getAllStringsInStatement:trimmedLine];
            //if (strings.count) {
                [dic setObject:strings forKey:trimmedLine];
            //}
        }
    }];
    
    return dic;
}


-(void)enumerateStringsInFileAtPath:(NSURL *)filePath withBlock:(void (^)(NSString *, NSArray *))block
{
    FileReader *fileReader = [[FileReader alloc] initReaderWithFileURL:filePath];
    
    [fileReader enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        
        BOOL hasString = NO;
        if ([line rangeOfString:@"@\""].location !=  NSNotFound) {
            hasString = YES;
        }
        
        NSArray *strings;
        
        if (hasString) {
            if ([self shouldLocalizeStatement:line])
            {
                strings = [self getAllStringsInStatement:line];
            }
        }
        
        if (block) {
            block(line, strings);
        }
    }];
    
    
}


-(NSArray *)getAllStringsInStatement:(NSString *)statement
{
    NSMutableArray *strings = [NSMutableArray array];
    
    NSString *trimmedStatement = [statement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSScanner *scanner = [NSScanner scannerWithString:trimmedStatement];
    
    while (!scanner.isAtEnd) 
    {    
        [scanner scanUpToString:@"@\"" intoString:nil];
        if ([scanner isAtEnd]) {
            break;
        }
        scanner.scanLocation += 2;
        NSString *string;
        [scanner scanUpToString:@"\"" intoString:&string];
        if (string) {
            NSString *temp = [string copy];
            
            // check for \" in the string
            while ([temp hasSuffix:@"\\"] && !scanner.isAtEnd) {
                // this was escaped string, update scan location and search for the "
                scanner.scanLocation += 1;
                temp = nil;
                [scanner scanUpToString:@"\"" intoString:&temp];
                string = [string stringByAppendingFormat:@"\"%@", (temp ? temp : @"")];
            }
            // here we have the final string with the " suffix
            
            if ([self shouldLocalizeString:string]) 
            {       
                string = [NSString stringWithFormat:@"@\"%@\"", string];
                NSRange stringRange = [statement rangeOfString:string];
                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:string, @"string", NSStringFromRange(stringRange), @"range", nil];
                [strings addObject:dic]; // add string to the array
            }
        }
    }
    //NSLog(@"strings: %@ in statement: %@" ,strings, statement);
    return strings;
}

-(BOOL)shouldLocalizeStatement:(NSString *)statement
{
    NSString *trimmedStatement = [statement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([statement rangeOfString:@"@"].location == NSNotFound) {
        return NO;
    }
    
    if (!statement || !statement.length || !trimmedStatement ||!trimmedStatement.length) {
        // if nil or empty or spaces
        return NO;
    }
    
    if ([trimmedStatement hasPrefix:@"//"] || [trimmedStatement hasPrefix:@"/*"]) {
        //NSLog(@"commented");
        return NO;
    }
    
    if ([trimmedStatement hasPrefix:@"NSLog"]) {
        //NSLog(@"Logger");
        return NO;
    }
    
    // check if it's already localized
    if ([statement rangeOfString:@"NSLocalizedString("].location != NSNotFound) {
        //NSLog(@"already localized !!");
        return NO;
    }
    
    // check for Notification
    if ([trimmedStatement rangeOfString:@"NSNotificationCenter"].location != NSNotFound) {
        //NSLog(@"Notification");
        return NO;
    }
    
    // check for animationWithKeyPath
    if ([trimmedStatement rangeOfString:@"animationWithKeyPath"].location != NSNotFound) {
        //NSLog(@"Animation");
        return NO;
    }
    
    // check for nib names
    if ([trimmedStatement rangeOfString:@"NibName"].location != NSNotFound) {
        //NSLog(@"Nib Name");
        return NO;
    }
    
    // check for nib names
    if ([trimmedStatement rangeOfString:@"storyboardWithName"].location != NSNotFound) {
        //NSLog(@"Nib Name");
        return NO;
    }
    
    // check for nib names
    if ([trimmedStatement rangeOfString:@"instantiateViewControllerWithIdentifier"].location != NSNotFound) {
        //NSLog(@"Nib Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedStatement rangeOfString:@"fetchObjectsForEntityName"].location != NSNotFound) {
        //NSLog(@"Entity Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedStatement rangeOfString:@"entityForName"].location != NSNotFound) {
        //NSLog(@"Entity Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedStatement rangeOfString:@"fetchRequestWithEntityName"].location != NSNotFound) {
        //NSLog(@"Entity Name");
        return NO;
    }
    
    // check for descriptors 
    if ([trimmedStatement rangeOfString:@"sortDescriptorWithKey"].location != NSNotFound) {
        //NSLog(@"Descriptor Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedStatement rangeOfString:@"insertNewObjectForEntityForName"].location != NSNotFound) {
        //NSLog(@"Entity Name");
        return NO;
    }
    
    // check for paths 
    if ([trimmedStatement rangeOfString:@"stringByAppendingPathComponent"].location != NSNotFound) {
        //NSLog(@"Entity Name");
        return NO;
    }
    
    // check for font names 
    if ([trimmedStatement rangeOfString:@"fontWithName"].location != NSNotFound) {
        //NSLog(@"Font Name");
        return NO;
    }
    
    // check for entities names 
    if ([trimmedStatement rangeOfString:@"predicateWithFormat"].location != NSNotFound) {
        //NSLog(@"Predicate");
        return NO;
    }
    
    // check for keys 
    if ([trimmedStatement rangeOfString:@"objectForKey"].location != NSNotFound) {
        //NSLog(@"Predicate");imageNamed
        return NO;
    }
    
    // check for images 
    if ([trimmedStatement rangeOfString:@"imageNamed"].location != NSNotFound) {
        //NSLog(@"Predicate");pathForResource
        return NO;
    }
    
    // check for resources names 
    if ([trimmedStatement rangeOfString:@"pathForResource"].location != NSNotFound) {
        //NSLog(@"Predicate");
        return NO;
    }
    
    // check for identifiers 
    if ([trimmedStatement rangeOfString:@"dequeueReusableCellWithIdentifier"].location != NSNotFound) {
        //NSLog(@"Predicate");setDateFormat
        return NO;
    }
    
    // check for DateFormats 
    if ([trimmedStatement rangeOfString:@"setDateFormat"].location != NSNotFound) {
        //NSLog(@"Predicate");
        return NO;
    }
    
    return YES;

}

-(BOOL)shouldLocalizeString:(NSString *)string
{
    NSString *trimmedString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    
    if (![trimmedString stringByReplacingOccurrencesOfString:@"%@" withString:@""].length || ![trimmedString stringByReplacingOccurrencesOfString:@"%i" withString:@""].length || ![trimmedString stringByReplacingOccurrencesOfString:@"%d" withString:@""].length) {
        //NSLog(@"format");
        return NO;
    }
    
    if ([trimmedString isEqualToString:@","] || [trimmedString isEqualToString:@";"] || [trimmedString isEqualToString:@"."] || [trimmedString isEqualToString:@"}"] || [trimmedString isEqualToString:@"{"] || [trimmedString isEqualToString:@")"] || [trimmedString isEqualToString:@"["] || [trimmedString isEqualToString:@"]"] || [trimmedString isEqualToString:@"("] || [trimmedString isEqualToString:@"-"] || [trimmedString isEqualToString:@"_"] || [trimmedString isEqualToString:@"/"] || [trimmedString isEqualToString:@"!"] || [trimmedString isEqualToString:@"%"]) 
    {
        //NSLog(@"special characters");
        return NO;
    }
    
    if ([trimmedString.pathExtension isEqualToString:@"png"] || [trimmedString.pathExtension isEqualToString:@"zip"]) {
        //NSLog(@"path extentions");
        return NO;
    }
    
    return YES;
}
@end
