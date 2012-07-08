//
//  LocalizerWindowController.m
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "LocalizerWindowController.h"

#import "Localizer.h"

static dispatch_queue_t _localize_strings_queue;
static dispatch_queue_t localize_strings_queue()
{
    if (!_localize_strings_queue) {
        _localize_strings_queue = dispatch_queue_create("com.inovaton.p-localizer.localize-strings-array", DISPATCH_QUEUE_SERIAL);
    }
    return _localize_strings_queue;
}

@interface LocalizerWindowController ()

@property (strong, nonatomic) NSMutableArray *stringsArray;

@property (assign) NSRange lastSelectedRange;

@end

@implementation LocalizerWindowController
@synthesize outline;
@synthesize textView = _textView;
@synthesize stringsTable = _stringsTable;
@synthesize pathURL = _pathURL;
@synthesize directory = _directory;
@synthesize fileEntity = _fileEntity;
@synthesize stringsArray = _stringsArray;
@synthesize lastSelectedRange = _lastSelectedRange;

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

#pragma mark -
#pragma mark - OutlineDataSource

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
    [self.textView setString:@""];
    self.stringsArray = [NSMutableArray array];
    id item = [self.outline itemAtRow:self.outline.selectedRow];
    if ([item isMemberOfClass:[FilePathEntity class]]) {
        // read file of that item
        FilePathEntity *file = item;
        
        __unsafe_unretained __block  LocalizerWindowController *weakSelf = self;
        
        dispatch_async(localize_strings_queue(), ^{

            [[Localizer defaultLocalizer] enumerateStringsInFileAtPath:file.fileURL withBlock:^(NSString *line, NSArray *strings) {
                [weakSelf.stringsArray addObjectsFromArray:strings];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.textView setString:[[weakSelf.textView string] stringByAppendingString:line]];
                });
            }];
            
            [weakSelf.stringsArray enumerateObjectsUsingBlock:^(NSDictionary *string, NSUInteger idx, BOOL *stop) {
                NSString *val = [string objectForKey:@"string"];
                NSRange range = [weakSelf.textView.string rangeOfString:val];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.textView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
                });
            }];
            
            [weakSelf.stringsTable reloadData];
            
            weakSelf = nil;
        });
        
//        
//        
//        NSString *string = [NSString stringWithContentsOfURL:file.fileURL encoding:NSUTF8StringEncoding error:nil];
//        [self.textView setString:string];
//        
//        NSDictionary *data = [[Localizer defaultLocalizer] localizeStringsInFilesAtPath:file.fileURL];
//        NSLog(@"data: %@", data);
//        
//        [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *strings, BOOL *stop) {
//            if (strings.count) {
//                [strings enumerateObjectsUsingBlock:^(NSDictionary *stringValue, NSUInteger idx, BOOL *stop) {
//                    NSString *str = [stringValue objectForKey:@"string"];
//                    
//                    NSRange range = [string rangeOfString:str];
//                    
//                    [self.textView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
//                }];
//            }
//        }];
    }
}


#pragma mark -
#pragma mark - TableViewDataSource

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.stringsArray.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"StringCell" owner:self];
    
    result.textField.stringValue = [[self.stringsArray objectAtIndex:row] objectForKey:@"string"];
    
    return result;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.lastSelectedRange.location != NSNotFound) {
        [self.textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:self.lastSelectedRange];
    }
    
    NSDictionary *stringDic = [self.stringsArray objectAtIndex:self.stringsTable.selectedRow];
    NSString *string = [stringDic objectForKey:@"string"];
    NSRange range = [self.textView.string rangeOfString:string];
    [self.textView scrollRangeToVisible:range];
    [self.textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:range];
    [self.textView setNeedsDisplayInRect:self.textView.visibleRect];
    
    self.lastSelectedRange = range;
    
}

- (IBAction)changeStringState:(NSButton *)sender 
{
    NSInteger row = [self.stringsTable rowForView:sender];
    
    NSDictionary *stringDic = [self.stringsArray objectAtIndex:row];
    NSString *string = [stringDic objectForKey:@"string"];
    
    NSRange range = [self.textView.string rangeOfString:string];
    
    [self.textView replaceCharactersInRange:range withString:[NSString stringWithFormat:@"NSLocalizedString(%@, nil)", string]];
}
@end
