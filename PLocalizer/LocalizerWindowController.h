//
//  LocalizerWindowController.h
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FilePathEntity.h"

@interface LocalizerWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSOutlineView *outline;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTableView *stringsTable;

@property (strong, nonatomic) NSURL *pathURL;

@property (strong, nonatomic) FilePathEntity *fileEntity;
@property (strong, nonatomic) DirectoryEntity *directory;

- (IBAction)changeStringState:(id)sender;

- (IBAction)saveFile:(id)sender;
- (IBAction)localizeAll:(id)sender;

- (IBAction)delocalizeAll:(id)sender;

- (IBAction)finish:(id)sender;

@end
