//
//  AppDelegate.h
//  PLocalizer
//
//  Created by Ali Amin on 7/3/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LocalizerWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;


@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSTextField *labelView;

@property (strong) NSArray *dataSource;

@property (weak) IBOutlet NSProgressIndicator *spinner;

@property (weak) IBOutlet NSTextField *pathTextField;

@property (strong) LocalizerWindowController *localizerController;

@property (strong) NSURL *openURL;

- (IBAction)browseFiles:(id)sender;

- (IBAction)searchForCodeFiles:(id)sender;


@end
