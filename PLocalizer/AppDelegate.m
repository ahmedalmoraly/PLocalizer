//
//  AppDelegate.m
//  PLocalizer
//
//  Created by Ali Amin on 7/3/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "AppDelegate.h"
#import "Localizer.h"
#import "TableCell.h"
#import "LocalizerWindowController.h"

@implementation AppDelegate
@synthesize pathTextField = _pathTextField;
@synthesize openURL = _openURL;

@synthesize window = _window;
@synthesize tableView = _tableView;
@synthesize labelView = _labelView;
@synthesize dataSource = _dataSource;
@synthesize spinner = _spinner;
@synthesize localizerController = _localizerController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    // Insert code here to initialize your application
//    NSString *path = @"/Developer/Repos/TeacherPal/TeacherPalRemakeUI";
//    dispatch_queue_t background = dispatch_queue_create("background.queue", DISPATCH_QUEUE_CONCURRENT);
//    [self.spinner startAnimation:self.spinner];
//    dispatch_async(background, ^{
//        self.dataSource = [[Localizer defaultLocalizer] searchForStringsInDirectory:path];
//        NSLog(@"%@", self.dataSource);
//        self.labelView.stringValue = self.dataSource.description;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//            [self.tableView reloadData]; 
//            [self.spinner stopAnimation:self.spinner];
//        });
//    });
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.dataSource.count;
}

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    cell.textField.stringValue = [[self.dataSource objectAtIndex:row] allKeys].lastObject;
    return cell;
}

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    return YES;
}

- (IBAction)browseFiles:(id)sender 
{
    NSOpenPanel *open = [NSOpenPanel openPanel];
    
    open.canChooseFiles = NO;
    open.canChooseDirectories = YES;

    NSInteger resut = [open runModal];
    
    if (resut == NSOKButton) {
        self.pathTextField.stringValue = open.directoryURL.absoluteString;
        self.openURL = open.directoryURL;
    }
}

- (IBAction)searchForCodeFiles:(id)sender 
{
    self.localizerController = [[LocalizerWindowController alloc] initWithWindowNibName:@"LocalizerWindowController"];
    
    self.localizerController.pathURL = self.openURL;
    [self.localizerController showWindow:nil];
    [[self.localizerController window] makeMainWindow];
}
@end
