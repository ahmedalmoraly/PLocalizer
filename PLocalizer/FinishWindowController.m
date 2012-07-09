//
//  FinishWindowController.m
//  PLocalizer
//
//  Created by Ahmad al-Moraly on 7/9/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "FinishWindowController.h"

@interface FinishWindowController ()

@end

@implementation FinishWindowController
@synthesize pathURL = _pathURL;
@synthesize pathTextField = _pathTextField;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)generateStringsFile:(NSButton *)sender
{
    NSString *outPutPath = self.pathTextField.stringValue;
    NSString *cd_command = [NSString stringWithFormat:@"cd %@", self.pathURL.path];
    NSString *command = [NSString stringWithFormat:@"%@; find . -name \\*.m | xargs genstrings -o %@", cd_command, outPutPath];
        //find . -name \*.m | xargs genstrings -o en.lproj
    NSLog(@"command: %@", cd_command);
    NSLog(@"command: %@", command);
    int z = system(command.UTF8String);
    int y = system("genstrings -a *.m");
    
    
}

- (IBAction)browseForOutputPath:(id)sender
{
     NSOpenPanel *open = [NSOpenPanel openPanel];
    
    [open setDirectoryURL:self.pathURL];
    open.canChooseFiles = NO;
    open.canChooseDirectories = YES;

    NSInteger resut = [open runModal];
    
    if (resut == NSOKButton) {
        self.pathTextField.stringValue = open.directoryURL.path;
    }

}

@end
