//
//  DFViewController.h
//  DiskFiller
//
//  Created by Eric Fikus on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DFViewController : UIViewController
{
    IBOutlet UILabel *freeSpaceLabel;
    IBOutlet UILabel *statusLabel;
    IBOutlet UIButton *fillButton;
    IBOutlet UIButton *clearButton;
}
@end
