//
//  DFViewController.m
//  DiskFiller
//
//  Created by Eric Fikus on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DFViewController.h"

// Fill to 100M left
#define FULL (1024 * 1024 * 100)

@interface DFViewController ()

@end

@implementation DFViewController

- (uint64_t)freeSpace
{
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    
    NSError *error = nil;  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject]
                                                                                       error:&error];  
    
    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];  
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
//        NSLog(@"Memory Capacity of %llu MB with %llu MB free space available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    }
    else
    {
        NSLog(@"Error obtaining free space: Domain = %@, Code = %@", [error domain], [error code]);
    }  
    
    return totalFreeSpace;
}

-(NSString *)_prettyFreeSpace:(uint64_t)free suffixes:(NSArray *)suffixes
{
    if (free < (1024*1024) || suffixes.count == 2)
    {
        double d = free/1024.0;
        return [NSString stringWithFormat:@"%.1f%@", d, [suffixes objectAtIndex:1]];
    }
    return [self _prettyFreeSpace:free/1024 suffixes:[suffixes subarrayWithRange:NSMakeRange(1, suffixes.count-1)]];
}

-(NSString *)prettyFreeSpace:(uint64_t)free
{
    return [self _prettyFreeSpace:free suffixes:[NSArray arrayWithObjects:@"b", @"k", @"M", @"G", nil]];
}

-(uint64_t)junkFileSize
{
    return [self freeSpace] - FULL;
}

-(NSString *)documentsPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [paths lastObject];
}

-(NSString *)junkFilePath
{
    return [[self documentsPath] stringByAppendingPathComponent:@"junk"];
}

-(void)updateFreeSpace
{
    uint64_t freeSpace = [self freeSpace];
    freeSpaceLabel.text = [NSString stringWithFormat:@"Free space: %@", [self prettyFreeSpace:freeSpace]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIColor *c = [UIColor grayColor];
    [fillButton setTitleColor:c forState:UIControlStateDisabled];
    [clearButton setTitleColor:c forState:UIControlStateDisabled];
    [fillButton addTarget:self action:@selector(fillPressed:) forControlEvents:UIControlEventTouchUpInside];
    [clearButton addTarget:self action:@selector(clearPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self updateFreeSpace];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

-(void)setButtonsEnabled:(BOOL)enabled
{
    fillButton.enabled = clearButton.enabled = enabled;
}

-(void)fillPressed:(id)sender
{
    statusLabel.text = @"Filling…";
    [self setButtonsEnabled:NO];
    [self performSelectorInBackground:@selector(fill) withObject:nil];
}

-(void)clearPressed:(id)sender
{
    statusLabel.text = @"Clearing…";
    [self setButtonsEnabled:NO];
    [self performSelectorInBackground:@selector(clear) withObject:nil];
}

-(void)fill
{
    const char *path = [[self junkFilePath] cStringUsingEncoding:NSUTF8StringEncoding];
    uint64_t size = [self junkFileSize];
    FILE *fp = fopen(path, "a");
    uint64_t written = 0;
    size_t bufSize = 1024 * 1024;
    char *junk = malloc(bufSize);
    while (written < size)
    {
        written += fwrite(junk, bufSize, 1, fp) * bufSize;
        [self performSelectorOnMainThread:@selector(updateFreeSpace) withObject:nil waitUntilDone:NO];
    }
    fclose(fp);
    free(junk);
    [self performSelectorOnMainThread:@selector(fillDone) withObject:nil waitUntilDone:NO];
}

-(void)clear
{
    NSString *path = [self junkFilePath];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    [self performSelectorOnMainThread:@selector(clearDone) withObject:nil waitUntilDone:NO];
}

-(void)fillDone
{
    statusLabel.text = @"Ready";
    [self updateFreeSpace];
    [self setButtonsEnabled:YES];
}

-(void)clearDone
{
    statusLabel.text = @"Ready";
    [self updateFreeSpace];
    [self setButtonsEnabled:YES];
}

@end
