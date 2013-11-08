//
//  SVWebViewController.m
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewController.h"
#import "Reachability.h"

@interface SVWebViewController () <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong, readonly) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong, readonly) UIBarButtonItem *actionBarButtonItem;
@property (nonatomic, strong, readonly) UIActionSheet *pageActionSheet;

@property (nonatomic, strong) UIWebView *mainWebView;
//@property (nonatomic, strong) NSURL *URL;

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

@synthesize availableActions;

@synthesize URL, mainWebView, isAlreadyLoad;
@synthesize backBarButtonItem, forwardBarButtonItem, refreshBarButtonItem, stopBarButtonItem, actionBarButtonItem, pageActionSheet;

#pragma mark - setters and getters

- (UIBarButtonItem *)backBarButtonItem {
    
    if (!backBarButtonItem) {
        backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBackClicked:)];
        backBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		backBarButtonItem.width = 18.0f;
    }
    return backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    
    if (!forwardBarButtonItem) {
        forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/iPhone/forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForwardClicked:)];
        forwardBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
		forwardBarButtonItem.width = 18.0f;
    }
    return forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    
    if (!refreshBarButtonItem) {
        refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    }
    
    return refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    
    if (!stopBarButtonItem) {
        stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    }
    return stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    
    if (!actionBarButtonItem) {
        actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    }
    return actionBarButtonItem;
}

- (UIActionSheet *)pageActionSheet {
    
    if(!pageActionSheet) {
        pageActionSheet = [[UIActionSheet alloc]
						   initWithTitle:nil
						   delegate:self
						   cancelButtonTitle:nil
						   destructiveButtonTitle:nil
						   otherButtonTitles:nil];
		
        if((self.availableActions & SVWebViewControllerAvailableActionsCopyLink) == SVWebViewControllerAvailableActionsCopyLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")];
        
        if((self.availableActions & SVWebViewControllerAvailableActionsOpenInSafari) == SVWebViewControllerAvailableActionsOpenInSafari)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")];
        
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]] && (self.availableActions & SVWebViewControllerAvailableActionsOpenInChrome) == SVWebViewControllerAvailableActionsOpenInChrome)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")];
        
        if([MFMailComposeViewController canSendMail] && (self.availableActions & SVWebViewControllerAvailableActionsMailLink) == SVWebViewControllerAvailableActionsMailLink)
            [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")];
        
        [pageActionSheet addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"SVWebViewController", @"")];
        pageActionSheet.cancelButtonIndex = [self.pageActionSheet numberOfButtons]-1;
    }
    
    return pageActionSheet;
}

#pragma mark - Initialization

- (id)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (id)initWithURL:(NSURL*)pageURL {
    
    if(self = [super init]) {
        self.URL = pageURL;
        self.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsOpenInChrome | SVWebViewControllerAvailableActionsMailLink;
    }
    
    return self;
}

- (void)loadURL:(NSURL *)pageURL {
    NSLog(@"loadURL");
    [mainWebView loadRequest:[NSURLRequest requestWithURL:pageURL]];
}

#pragma mark - View lifecycle

- (void)loadView {
    NSLog(@"loadView");

    mainWebView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    mainWebView.delegate = self;
    mainWebView.scalesPageToFit = YES;
    [self loadURL:self.URL];
    self.view = mainWebView;

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
            [[[mainWebView subviews] objectAtIndex:0] addSubview:self.noConnectionView];

        });
    };
    
    [reach startNotifier];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    mainWebView = nil;
    backBarButtonItem = nil;
    forwardBarButtonItem = nil;
    refreshBarButtonItem = nil;
    stopBarButtonItem = nil;
    actionBarButtonItem = nil;
    pageActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
	[super viewWillAppear:animated];
	
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationItem.title = @"WEBSITE";

    isAlreadyLoad = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];/* initialize your button */
//    UIImage *image = [UIImage imageNamed:@"back-btn~ipad.png"];
//    [button setImage:image forState:UIControlStateNormal];
//    button.frame = CGRectMake(0, 0, (image.size.width *2), (image.size.height *2));
//    [button addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
//    
//    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
//    self.navigationItem.leftBarButtonItem = barButtonItem;
//    self.navigationItem.hidesBackButton = YES;
    
//    [self loadURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"Webview_URL",@"SVWebViewController", @"")]];
//    [self setURL:[NSURL URLWithString:NSLocalizedStringFromTable(@"Webview_URL",@"SVWebViewController", @"")]];
    
//    [Flurry logEvent:@"WEBVIEW"];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
	if (DeviceSystemMajorVersion() >= 7) {
		[self hideActionSheetIfVisible];
	}
	
	
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

- (void)dealloc
{
    [mainWebView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    mainWebView.delegate = nil;
}

#pragma mark - Toolbar

- (void)updateToolbarItems {
	
	if (self.hideToolbar) {
		self.navigationItem.rightBarButtonItems = nil;
		 [self.navigationController setToolbarHidden:YES animated:NO];
		return;
	}
	
    self.backBarButtonItem.enabled = self.mainWebView.canGoBack;
    self.forwardBarButtonItem.enabled = self.mainWebView.canGoForward;
    self.actionBarButtonItem.enabled = !self.mainWebView.isLoading;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.mainWebView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSArray *items;
        CGFloat toolbarWidth = 250.0f;
        
        if(self.availableActions == 0) {
            toolbarWidth = 200.0f;
            items = [NSArray arrayWithObjects:
                     fixedSpace,
                     refreshStopBarButtonItem,
                     flexibleSpace,
                     self.backBarButtonItem,
                     flexibleSpace,
                     self.forwardBarButtonItem,
                     fixedSpace,
                     nil];
        } else {
			
			if (DeviceSystemMajorVersion() < 7) {
				
				items = [NSArray arrayWithObjects:
						 fixedSpace,
						 refreshStopBarButtonItem,
						 flexibleSpace,
						 self.backBarButtonItem,
						 flexibleSpace,
						 self.forwardBarButtonItem,
						 flexibleSpace,
						 self.actionBarButtonItem,
						 fixedSpace,
						 nil];
			} else {
				// iOS 7 Support
				items = [NSArray arrayWithObjects:
						 fixedSpace,
						 self.actionBarButtonItem,
						 fixedSpace,
						 self.forwardBarButtonItem,
						 fixedSpace,
						 self.backBarButtonItem,
						 fixedSpace,
						 refreshStopBarButtonItem,
						 fixedSpace,
						 nil];
			}
        }
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
		toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;

		
		if (DeviceSystemMajorVersion() < 7)
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
		else {
			self.navigationItem.rightBarButtonItems = items;
            toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        }

		
    } else {
		// iPhone
		
        NSArray *items;
        
        if(self.availableActions == 0) {
            items = [NSArray arrayWithObjects:
                     flexibleSpace,
                     self.backBarButtonItem,
                     flexibleSpace,
                     self.forwardBarButtonItem,
                     flexibleSpace,
                     refreshStopBarButtonItem,
                     flexibleSpace,
                     nil];
        } else {
            items = [NSArray arrayWithObjects:
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
        }
        
		self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
		self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        if (DeviceSystemMajorVersion() < 7) {
            
        }
        else {
            self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        }
        self.toolbarItems = items;
    }
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    NSLog(@"webViewDidStartLoad");
    if (!isAlreadyLoad) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        isAlreadyLoad = YES;

    }
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [self updateToolbarItems];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSLog(@"webViewDidFinishLoad");
    
    isAlreadyLoad = NO;

    [MBProgressHUD hideHUDForView:self.view animated:YES];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
	if (!self.hideToolbar) {
//		self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.navigationItem.title = @"WEBSITE";
		[self updateToolbarItems];
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    NSLog(@"didFailLoadWithError %@", error);

    [MBProgressHUD hideHUDForView:self.view animated:YES];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [self updateToolbarItems];
}

#pragma mark - Target actions

- (void)goBackClicked:(UIBarButtonItem *)sender {
    [mainWebView goBack];
}

- (void)goForwardClicked:(UIBarButtonItem *)sender {
    [mainWebView goForward];
}

- (void)reloadClicked:(UIBarButtonItem *)sender {
    [mainWebView reload];
}

- (void)stopClicked:(UIBarButtonItem *)sender {
    [mainWebView stopLoading];
	[self updateToolbarItems];
}

- (void)actionButtonClicked:(id)sender {
	
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if (self.pageActionSheet.visible) {
			[self.pageActionSheet dismissWithClickedButtonIndex:self.pageActionSheet.cancelButtonIndex animated:NO];
		} else
			[self.pageActionSheet showFromBarButtonItem:self.actionBarButtonItem animated:YES];
	}
    else {
		if (self.pageActionSheet.visible) {
			[self.pageActionSheet dismissWithClickedButtonIndex:self.pageActionSheet.cancelButtonIndex animated:NO];
		} else
			[self.pageActionSheet showFromToolbar:self.navigationController.toolbar];
	}
    
}

- (void)doneButtonClicked:(id)sender {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
    [self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
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
//        [self.view addSubview:self.noConnectionView];
//        notificationLabel.text = @"Notification Says Unreachable";
//        self.view = self.noConnectionView;
        
        [[[mainWebView subviews] objectAtIndex:0] addSubview:self.noConnectionView];

    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Safari", @"SVWebViewController", @"")] == NSOrderedSame)
        [[UIApplication sharedApplication] openURL:self.mainWebView.request.URL];
    
    if([title localizedCompare:NSLocalizedStringFromTable(@"Open in Chrome", @"SVWebViewController", @"")] == NSOrderedSame) {
        NSURL *inputURL = self.mainWebView.request.URL;
        NSString *scheme = inputURL.scheme;
        
        NSString *chromeScheme = nil;
        if ([scheme isEqualToString:@"http"]) {
            chromeScheme = @"googlechrome";
        } else if ([scheme isEqualToString:@"https"]) {
            chromeScheme = @"googlechromes";
        }
        
        if (chromeScheme) {
            NSString *absoluteString = [inputURL absoluteString];
            NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
            NSString *urlNoScheme =
            [absoluteString substringFromIndex:rangeForScheme.location];
            NSString *chromeURLString =
            [chromeScheme stringByAppendingString:urlNoScheme];
            NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
            
            [[UIApplication sharedApplication] openURL:chromeURL];
        }
    }
    
    if([title localizedCompare:NSLocalizedStringFromTable(@"Copy Link", @"SVWebViewController", @"")] == NSOrderedSame) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.mainWebView.request.URL.absoluteString;
    }
    
    else if([title localizedCompare:NSLocalizedStringFromTable(@"Mail Link to this Page", @"SVWebViewController", @"")] == NSOrderedSame) {
        
		MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        
		mailViewController.mailComposeDelegate = self;
        [mailViewController setSubject:[self.mainWebView stringByEvaluatingJavaScriptFromString:@"document.title"]];
  		[mailViewController setMessageBody:self.mainWebView.request.URL.absoluteString isHTML:NO];
		mailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
		[self presentModalViewController:mailViewController animated:YES];
#else
        [self presentViewController:mailViewController animated:YES completion:NULL];
#endif
	}
    
    pageActionSheet = nil;
}

- (void) hideActionSheetIfVisible {
	if (self.pageActionSheet.visible) {
		[self.pageActionSheet dismissWithClickedButtonIndex:self.pageActionSheet.cancelButtonIndex animated:NO];
	}
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
	[self dismissModalViewControllerAnimated:YES];
#else
    [self dismissViewControllerAnimated:YES completion:NULL];
#endif
}


NSUInteger DeviceSystemMajorVersion() {
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
	});
	return _deviceSystemMajorVersion;
}

//- (BOOL)prefersStatusBarHidden
//{
//    return YES;
//}

@end
