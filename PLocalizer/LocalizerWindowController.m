//
//  LocalizerWindowController.m
//  PLocalizer
//
//  Created by Ali Amin on 7/5/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import "LocalizerWindowController.h"
#import "FileReader.h"
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
        
                NSMutableAttributedString *attibutedString = [[NSMutableAttributedString alloc] initWithString:line];
                
                __weak NSMutableAttributedString *weakString = attibutedString;
                
                [strings enumerateObjectsUsingBlock:^(NSDictionary *stringDic, NSUInteger idx, BOOL *stop) {
                    NSRange range = NSRangeFromString([stringDic objectForKey:@"range"]);
                    
                    [weakString setAttributes:[NSDictionary dictionaryWithObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName] range:range];
                }];
                
                    // get the range of the line
                NSRange lineRange = NSMakeRange(self.textView.string.length, attibutedString.length);
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakSelf.textView.textStorage beginEditing];
                    [weakSelf.textView.textStorage appendAttributedString:weakString];
                    [weakSelf.textView.textStorage endEditing];
                });
                
                
                [strings enumerateObjectsUsingBlock:^(NSMutableDictionary *stringDic, NSUInteger idx, BOOL *stop) {
                    [stringDic setObject:NSStringFromRange(lineRange) forKey:@"lineRange"];
                }];
                
                [weakSelf.stringsArray addObjectsFromArray:strings];
            }];
            
            [weakSelf.stringsTable reloadData];
            
            weakSelf = nil;
        });
        
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

    NSDictionary *stringDic = [self.stringsArray objectAtIndex:row];

    result.textField.stringValue = [stringDic objectForKey:@"string"];
    
    NSButton *check = [result viewWithTag:1];
    
    if ([stringDic objectForKey:@"localizedString"]) {
        check.state = 1;
    }
    else {
        check.state = 0;
    }
    
    return result;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.lastSelectedRange.location != NSNotFound) {
        [self.textView.textStorage removeAttribute:NSBackgroundColorAttributeName range:self.lastSelectedRange];
    }
    
    NSDictionary *stringDic = [self.stringsArray objectAtIndex:self.stringsTable.selectedRow];
    
    NSString *string = [stringDic objectForKey:@"localizedString"];
    
    if (!string) {
        string = [stringDic objectForKey:@"string"];
    }
    
    NSRange lineRange =  NSRangeFromString([stringDic objectForKey:@"lineRange"]);
    
    NSRange range = [self.textView.string rangeOfString:string options:NSCaseInsensitiveSearch range:lineRange];
    
    [self.textView scrollRangeToVisible:range];
    [self.textView.textStorage addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:range];
    [self.textView setNeedsDisplayInRect:self.textView.visibleRect];
    
    self.lastSelectedRange = range;
    
}

- (IBAction)changeStringState:(NSButton *)sender 
{
    NSInteger row = [self.stringsTable rowForView:sender];
    
    NSMutableDictionary *stringDic = [self.stringsArray objectAtIndex:row];
    
    NSRange lineRange =  NSRangeFromString([stringDic objectForKey:@"lineRange"]);
    
    NSString *string = [stringDic objectForKey:@"string"];
    
    NSInteger diffInLength = 0;
    NSString *localizedString = [stringDic objectForKey:@"localizedString"];
    if (localizedString) 
    {
            // string needs de-localization
        NSRange localizedRange = [self.textView.string rangeOfString:localizedString options:NSCaseInsensitiveSearch range:lineRange];
        
        [self.textView replaceCharactersInRange:localizedRange withString:string];
        
        [stringDic removeObjectForKey:@"localizedString"];
        
        diffInLength = string.length - localizedString.length;
    } 
    else
    {
            // string needs localization
        localizedString = [NSString stringWithFormat:@"NSLocalizedString(%@, nil)", string];
        
        NSRange range = [self.textView.string rangeOfString:string options:NSCaseInsensitiveSearch range:lineRange];
        
        [self.textView replaceCharactersInRange:range withString:localizedString];
        
        [stringDic setObject:localizedString forKey:@"localizedString"];
        
        diffInLength = localizedString.length - string.length;
        
        
    }
    
    lineRange.length += diffInLength;
    [stringDic setObject:NSStringFromRange(lineRange) forKey:@"lineRange"];
    
        // update range of all strings
    for (int idx = row+1; idx < self.stringsArray.count; idx++)
    {
        NSMutableDictionary *stringDic = [self.stringsArray objectAtIndex:idx];
        NSRange lineRange =  NSRangeFromString([stringDic objectForKey:@"lineRange"]);
        lineRange.location += diffInLength;
        [stringDic setObject:NSStringFromRange(lineRange) forKey:@"lineRange"];
    }
    
    [self.textView setNeedsDisplayInRect:self.textView.visibleRect];
}

- (IBAction)saveFile:(id)sender 
{
    FilePathEntity *file = [self.outline itemAtRow:self.outline.selectedRow];
    
    NSError *error;
    NSLog(@"%@", self.textView.textStorage.string);
    [self.textView.textStorage.string writeToURL:file.fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    NSLog(@"%@", error);
}

- (IBAction)localizeAll:(id)sender 
{
    for (int idx = 0; idx < self.stringsTable.numberOfRows; idx++) {
        NSButton *check = [[self tableView:self.stringsTable viewForTableColumn:self.stringsTable.tableColumns.lastObject row:idx] viewWithTag:1];
        
        [self changeStringState:check];
    }
}

- (IBAction)delocalizeAll:(id)sender 
{
    for (int idx = 0; idx < self.stringsTable.numberOfRows; idx++) {
        NSButton *check = [[self tableView:self.stringsTable viewForTableColumn:self.stringsTable.tableColumns.lastObject row:idx] viewWithTag:1];
        
        [self changeStringState:check];
    }
}


@end
