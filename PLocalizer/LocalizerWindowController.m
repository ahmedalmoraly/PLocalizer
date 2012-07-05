//
//  LocalizerWindowController.m
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "LocalizerWindowController.h"

#import "Localizer.h"

@interface LocalizerWindowController ()

@end

@implementation LocalizerWindowController
@synthesize outline;
@synthesize textView = _textView;
@synthesize pathURL = _pathURL;
@synthesize directory = _directory;
@synthesize fileEntity = _fileEntity;

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
    
    [self addObserver:self forKeyPath:@"self.directory.files" options:NSKeyValueObservingOptionNew context:NULL];
    self.directory = [[DirectoryEntity alloc] initWithFileURL:self.pathURL];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"self.directory.files"]) {
        [self.outline reloadData];
    }
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"self.directory.files"];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return self.directory.files.count;
    } 
    else if ([item isKindOfClass:[DirectoryEntity class]]) 
    {
        return ((DirectoryEntity *)item).files.count;
    }
    else {
        return 0;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [self.directory.files objectAtIndex:index];
    } 
    else {
        return [((DirectoryEntity *)item).files objectAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[DirectoryEntity class]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[DirectoryEntity class]];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[DirectoryEntity class]]) {
        // Everything is setup in bindings
        return [outlineView makeViewWithIdentifier:@"FolderCell" owner:self];
    } 
    else {
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"FileCell" owner:self];
        
        result.textField.stringValue = [(FilePathEntity *)item fileURL].lastPathComponent;
        return result;
    }
    return nil;
}    

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    id item = [self.outline itemAtRow:self.outline.selectedRow];
    if ([item isMemberOfClass:[FilePathEntity class]]) {
        // read file of that item
        FilePathEntity *file = item;
        NSString *string = [NSString stringWithContentsOfURL:file.fileURL encoding:NSUTF8StringEncoding error:nil];
        [self.textView setString:string];
        
        NSDictionary *data = [[Localizer defaultLocalizer] localizeStringsInFilesAtPath:file.fileURL];
        NSLog(@"data: %@", data);
    }
}

@end
