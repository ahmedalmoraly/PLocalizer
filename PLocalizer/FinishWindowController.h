//
//  FinishWindowController.h
//  PLocalizer
//
//  Created by Ahmad al-Moraly on 7/9/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FinishWindowController : NSWindowController

@property (strong, nonatomic) NSURL *pathURL;
@property (weak) IBOutlet NSTextField *pathTextField;

-(IBAction)generateStringsFile:(NSButton*)sender;
- (IBAction)browseForOutputPath:(id)sender;

@end
