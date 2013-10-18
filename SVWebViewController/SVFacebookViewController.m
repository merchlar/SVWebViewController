//
//  SVFacebookViewController.m
//  HungerGames
//
//  Created by FrancoisJulien ALCARAZ on 2013-10-18.
//
//

#import "SVFacebookViewController.h"

@interface SVFacebookViewController ()

@end

@implementation SVFacebookViewController

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
