//
//  SVFaceBookViewController.m
//  LiveToune
//
//  Created by FrancoisJulien ALCARAZ on 2013-10-22.
//  Copyright (c) 2013 Merchlar. All rights reserved.
//

#import "SVFaceBookViewController.h"

@interface SVFaceBookViewController ()

@end

@implementation SVFaceBookViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.navigationItem.title = @"FACEBOOK";
    
}

@end
