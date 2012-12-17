//
//  PPrYvSettingViewController.h
//  AT PrYv
//
//  Created by Nicolas Manzini on 13.12.12.
//  Copyright (c) 2012 PrYv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface PPrYvSettingViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UILabel * timeFilterLabel;
@property (strong, nonatomic) UILabel * distanceFilterLabel;
@property (weak, nonatomic) IBOutlet UINavigationItem *navItems;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bLogOut;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *bReturn;
@property (weak, nonatomic) UIPopoverController * iPadHoldingPopOver;
@property (weak, nonatomic) UIViewController * iPadHoldingPopOverViewController;

- (IBAction)dismissOptions:(id)sender;
- (IBAction)logOutCurrentUser:(id)sender;
- (void)changeLocationManagerTimeInterval:(UISlider *)timeIntervalSlider;
- (void)changeLocationManagerDistanceFilter:(UISlider *)distanceIntervalSlider;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

@end
