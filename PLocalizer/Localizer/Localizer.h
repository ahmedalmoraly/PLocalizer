//
//  Localizer.h
//  PLocalizer
//
//  Created by Ali Amin on 7/3/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Localizer : NSObject

+(Localizer *)defaultLocalizer;

-(NSArray *)searchForStringsInDirectory:(NSString *)path;

-(NSDictionary *)localizeStringsInFilesAtPath:(NSURL *)filePath;

@end
