//
//  WebViewController.h
//  beaconmanager.de
//
//  Created by pape on 02.06.14.
//  Copyright (c) 2014 1000eyes GmbH. All rights reserved.
//  Strictly Confidential
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UINavigationBarDelegate> {
    IBOutlet UIWebView *webView;
    IBOutlet UINavigationBar *navBar;
    IBOutlet UINavigationItem *navItem;
    NSURLRequest *reqURI;
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) IBOutlet UINavigationItem *navItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andURI:(NSURLRequest *)uri;
- (void)closeVC ;
@end
