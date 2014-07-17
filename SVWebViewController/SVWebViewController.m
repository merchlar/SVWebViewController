//
//  SVWebViewController.m
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewControllerActivityChrome.h"
#import "SVWebViewControllerActivitySafari.h"
#import "SVWebViewController.h"
#import "Reachability.h"
#import "S1AppDelegate.h"
#import "Flurry.h"

@interface SVWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarButtonItem;

@property (nonatomic, strong) UIWebView *webView;

- (id)initWithAddress:(NSString*)urlString;
- (id)initWithURL:(NSURL*)URL;
- (void)loadURL:(NSURL*)URL;

- (void)updateToolbarItems;

- (void)goBackClicked:(UIBarButtonItem *)sender;
- (void)goForwardClicked:(UIBarButtonItem *)sender;
- (void)reloadClicked:(UIBarButtonItem *)sender;
- (void)stopClicked:(UIBarButtonItem *)sender;
- (void)actionButtonClicked:(UIBarButtonItem *)sender;

@end


@implementation SVWebViewController

#pragma mark - Initialization

- (void)dealloc {
    [self.webView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.delegate = nil;
}

- (id)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL*)pageURL {
    
    if(self = [super init]) {
        self.URL = pageURL;
    }
    
    return self;
}

- (void)loadURL:(NSURL *)pageURL {
    [self.webView loadRequest:[NSURLRequest requestWithURL:pageURL]];
}

- (void)setURL:(NSURL *)URL {
    
    if (_URL != URL) {
        _URL = URL;
        [self loadURL:URL];

    }
    
}

#pragma mark - View lifecycle

- (void)loadView {
    self.view = self.webView;
    [self loadURL:self.URL];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.noConnectionView = [[[NSBundle mainBundle] loadNibNamed:@"NoConnectionView-iPhone" owner:self options:nil] objectAtIndex:0];
    }
    else {
        self.noConnectionView = [[[NSBundle mainBundle] loadNibNamed:@"NoConnectionView-iPad" owner:self options:nil] objectAtIndex:0];
    }
}

- (void)viewDidLoad {
	[super viewDidLoad];
    [self updateToolbarItems];
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"viewDidLoad reachableBlock");

//            blockLabel.text = @"Block Says Reachable";
//            self.view = mainWebView;
            [self.noConnectionView removeFromSuperview];
//            [self loadView];
			// TODO : maybe we need to reload the page here
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
//            blockLabel.text = @"Block Says Unreachable";
//            self.view = self.noConnectionView;
            NSLog(@"viewDidLoad unreachableBlock");
//            [self.view addSubview:self.noConnectionView];
            [[[self.webView subviews] objectAtIndex:0] addSubview:self.noConnectionView];
            
            [Flurry logError:[NSString stringWithFormat:@"%@_ERROR_VIEW", self.urlTitle] message:@"no connection available" error:nil];


        });
    };
    
    [reach startNotifier];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.webView = nil;
    _backBarButtonItem = nil;
    _forwardBarButtonItem = nil;
    _refreshBarButtonItem = nil;
    _stopBarButtonItem = nil;
    _actionBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
	[super viewWillAppear:animated];
	
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationItem.title = self.urlTitle;

    _isAlreadyLoad = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
    [Flurry logEvent:[NSString stringWithFormat:@"%@_VIEW", self.urlTitle]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Getters

- (UIWebView*)webView {
    if(!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _webView.delegate = self;
        _webView.scalesPageToFit = YES;
    }
    return _webView;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerBack"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(goBackClicked:)];
		_backBarButtonItem.width = 18.0f;
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerNext"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goForwardClicked:)];
		_forwardBarButtonItem.width = 18.0f;
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (!_actionBarButtonItem) {
        _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    }
    return _actionBarButtonItem;
}

#pragma mark - Toolbar

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.self.webView.canGoForward;
    self.actionBarButtonItem.enabled = !self.self.webView.isLoading;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat toolbarWidth = 250.0f;
        fixedSpace.width = 35.0f;

        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          refreshStopBarButtonItem,
                          fixedSpace,
                          self.backBarButtonItem,
                          fixedSpace,
                          self.forwardBarButtonItem,
                          fixedSpace,
                          self.actionBarButtonItem,
                          nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
        toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }
    
    else {
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.backBarButtonItem,
                          flexibleSpace,
                          self.forwardBarButtonItem,
                          flexibleSpace,
                          refreshStopBarButtonItem,
                          flexibleSpace,
                          self.actionBarButtonItem,
                          fixedSpace,
                          nil];
        
        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.toolbarItems = items;
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    NSLog(@"webViewDidStartLoad");
    if (!_isAlreadyLoad) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _isAlreadyLoad = YES;

    }
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self updateToolbarItems];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSLog(@"webViewDidFinishLoad");
    
    _isAlreadyLoad = NO;

    [MBProgressHUD hideHUDForView:self.view animated:YES];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
//    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self updateToolbarItems];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    NSLog(@"didFailLoadWithError %@", error);
    
    
    [Flurry logError:[NSString stringWithFormat:@"%@_ERROR_VIEW", self.urlTitle] message:@"unable to reach webpage" error:error];


    [MBProgressHUD hideHUDForView:self.view animated:YES];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [self updateToolbarItems];
}

#pragma mark - Target actions

- (void)goBackClicked:(UIBarButtonItem *)sender {
    [self.webView goBack];
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [self.webView goForward];
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    [self.webView reload];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [self.webView stopLoading];
	[self updateToolbarItems];
}

- (void)actionButtonClicked:(id)sender {
    
    [Flurry logEvent:[NSString stringWithFormat:@"%@_SHARE_TAPPED", self.urlTitle]];

    NSArray *activities = @[[SVWebViewControllerActivitySafari new], [SVWebViewControllerActivityChrome new]];
    NSURL *url = self.webView.request.URL ? self.webView.request.URL : self.URL;
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:activities];
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        NSLog(@"completed dialog - activity: %@ - finished flag: %d", activityType, completed);
        
        [(S1AppDelegate *)[[UIApplication sharedApplication] delegate] styleApp];
        
        if (completed) {
            [Flurry logEvent:[NSString stringWithFormat:@"%@_SHARE_COMPLETED", self.urlTitle] withParameters:[NSDictionary dictionaryWithObject:activityType forKey:@"NETWORK"]];
        }
        
    }];
    
    [(S1AppDelegate *)[[UIApplication sharedApplication] delegate] unStyleApp];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Reachability methods

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        NSLog(@"reachabilityChanged reachableBlock");
        [self.noConnectionView removeFromSuperview];
//        notificationLabel.text = @"Notification Says Reachable";
//        self.view = mainWebView;

    }
    else
    {
        NSLog(@"reachabilityChanged unreachableBlock");
        
        [Flurry logError:[NSString stringWithFormat:@"%@_ERROR_VIEW", self.urlTitle] message:@"no connection available" error:nil];
        
//        [self.view addSubview:self.noConnectionView];
//        notificationLabel.text = @"Notification Says Unreachable";
//        self.view = self.noConnectionView;
        
        [[[self.webView subviews] objectAtIndex:0] addSubview:self.noConnectionView];

    }
}


@end
