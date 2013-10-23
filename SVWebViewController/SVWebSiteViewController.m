//
//  SVWebSiteViewController.m
//  LiveToune
//
//  Created by FrancoisJulien ALCARAZ on 10/23/2013.
//  Copyright (c) 2013 Merchlar. All rights reserved.
//

#import "SVWebSiteViewController.h"
#import "Flurry.h"

@interface SVWebSiteViewController ()

@end

@implementation SVWebSiteViewController

@synthesize firstPage;


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
    
    self.navigationItem.title = @"SITE WEB";
    
    firstPage = YES;

    
}

- (void)loadView {
    
    [super loadView];
    
    self.mainWebView.delegate = self;
    
    
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    if (firstPage) {
        
        [Flurry logEvent:@"WEBSITE_VIEW"];
        
        firstPage = NO;
        
    }
    
    
    [super webViewDidFinishLoad:webView];
    
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if (firstPage) {
        
        [Flurry logEvent:@"WEBSITE_ERROR"];
        
        firstPage = NO;
        
    }
        
    [super webView:webView didFailLoadWithError:error];
    
}

@end
