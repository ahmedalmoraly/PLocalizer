//
//  TableCell.h
//  PLocalizer
//
//  Created by Ali Amin on 7/4/12.
//  Copyright (c) 2012 Artgin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TableCell : NSTableCellView

@property (weak) IBOutlet NSButton *check;
@property (weak) IBOutlet NSTextField *text;
@end
