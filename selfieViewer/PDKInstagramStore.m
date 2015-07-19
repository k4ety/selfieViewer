//
//  PDKInstagramStore.m
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#define kClientID @"ff97a0dc91e743f78d2af822cfd07d11"
#define kRedirectURI @"http://localhost"
#define kBaseURL @"https://instagram.com/"
#define kInstagramAPIBaseURL @"https://api.instagram.com"
#define kAuthenticationURL @"oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=basic"

#import <UIKit/UIKit.h>
#import "PDKInstagramStore.h"
#import "PDKSelfie.h"

@interface PDKInstagramStore () <UIWebViewDelegate>
@property (nonatomic, strong) NSMutableData *jsonData;
@property (nonatomic, strong) NSMutableDictionary *jsonObject;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSArray *jsonKeys;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
@property (nonatomic, strong) UIView *view;

@property (nonatomic, strong) NSDictionary *pagination;
@end

@implementation PDKInstagramStore
+ (instancetype)sharedStore
{
    static PDKInstagramStore *_sharedStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedStore = [[super allocWithZone:nil] init];
    });
    
    return _sharedStore;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    return self.sharedStore;
}

- (instancetype)init
{
    self = [super init];
    _backgroundQueue = dispatch_queue_create("com.k4ety.selfieViewer.queue", DISPATCH_QUEUE_CONCURRENT);
    _collection = [NSMutableArray new];
return self;
}


#pragma mark - Instagram Signon WebView Code
- (void)getAuth:(UIView *)view
{
    _view = view;
    NSString* urlString = [kBaseURL stringByAppendingFormat:kAuthenticationURL,kClientID,kRedirectURI];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    _webView.delegate = self;
    [_webView sizeToFit];
    
    [_webView loadRequest:request];
    _webView.backgroundColor = [UIColor blackColor];
    _webView.layer.backgroundColor = [[UIColor blackColor] CGColor];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    NSLog(@"%@", request);
    NSString* urlString = [[request URL] absoluteString];
    NSURL *Url = [request URL];
    NSArray *UrlComponents = [Url pathComponents];
    
    if (UrlComponents.count == 1) {
        NSRange tokenParm = [urlString rangeOfString: @"access_token="];
        if (tokenParm.location != NSNotFound) {
            _accessToken = [urlString substringFromIndex: NSMaxRange(tokenParm)];

            NSRange endRange = [_accessToken rangeOfString: @"&"];
            if (endRange.location != NSNotFound) {
                _accessToken = [_accessToken substringToIndex: endRange.location];
            }
            [webView removeFromSuperview];
            _webView = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"gotUserToken" object:nil];
        }
    } else {
//        NSLog(@"%@", request);
        NSRange tokenParm = [urlString rangeOfString: @"next=/oauth/authorize/"];
        if (tokenParm.location != NSNotFound) {
            [_view addSubview:_webView];
        }
    }
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
//    NSLog(@"%@", webView);
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    NSLog(@"%@", webView);
}

#pragma mark - Instagram API code
-(void)getPicsWithTag: (NSString *)tag
{
    NSString *query = [NSString stringWithFormat:@"https://api.instagram.com/v1/tags/%@/media/recent?access_token=%@", tag, _accessToken];
    [self queryJSON:query];
}

-(void)getMorePics
{
    if (_pagination) {
//        NSLog(@"pagination: %@\n%@",  [_pagination.allKeys componentsJoinedByString:@","], _pagination);
        NSString *query = _pagination[@"next_url"];
        _pagination = nil;
        [self queryJSON:query];
    }
}

- (void)queryJSON: (NSString *)urlString
{
    _jsonData = [[NSMutableData alloc] init];
    _jsonObject = [[NSMutableDictionary alloc] init];
    
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    NSLog(@"\n  %@", url);
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
    _connection = conn;
}

// This method will be called several times as the data arrives
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Add the incoming chunk of data to the container we are keeping
    // The data always comes in the correct order
    [_jsonData appendData:data];
    return;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    if (_jsonData)
        _jsonObject = [NSJSONSerialization JSONObjectWithData:_jsonData options:NSJSONReadingAllowFragments error: &error];
    else
        NSLog(@"\n\nJSON Error: No data recieved from server.\n\n");
    
    if (_jsonObject) {
        _jsonKeys = [_jsonObject.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//        NSLog(@"\nJSON keys: %@", [_jsonKeys componentsJoinedByString:@","]);
        
#pragma mark - Parse JSON results from instagram
        if (_jsonObject[@"meta"][@"error_message"]) {
//            NSString* jsonString = [[NSString alloc] initWithData:_jsonData encoding:NSASCIIStringEncoding];
            NSLog(@"\nJSON Error from server:\n  %@\n  %@\n", _jsonObject[@"meta"][@"error_type"], _jsonObject[@"meta"][@"error_message"]);
        }
        
        NSArray *data;
        if (_jsonObject[@"data"]) {
            data = _jsonObject[@"data"];
        } else data = nil;
        [self parseData: data];
        
        if (_jsonObject[@"pagination"]) {
            _pagination = _jsonObject[@"pagination"];
        } else _pagination = nil;
    } else {
        NSString *errorStr = error.debugDescription;
        NSLog (@"%@", errorStr);
        NSString* jsonString = [[NSString alloc] initWithData:_jsonData encoding:NSASCIIStringEncoding];
        NSString *needle = @"around character ";
        NSInteger start = (NSInteger)[errorStr rangeOfString:needle].location + needle.length;
        if (start > 0) {
            NSInteger length = [[errorStr substringFromIndex:start] rangeOfString:@"."].location;
            NSInteger errorLocation = [[errorStr substringWithRange:NSMakeRange(start, length)] integerValue];
            if (errorLocation > 20) {
                errorLocation = errorLocation - 20;
            }
            else {
                errorLocation = 0;
            }
            NSLog(@"JSON Data =\n%@", [jsonString substringFromIndex:errorLocation]);
        }
    }
    _jsonData = nil;
    return;
}

// Process json data in parallel asynchronously
- (void)parseData:(NSArray *)data
{
//        NSLog(@"Count = %lu\n%@", (unsigned long)data.count, data[1]);
// id,comments,created_time,caption,link,tags,likes,type,users_in_photo,location,filter,images,user_has_liked,user,attribution
    for (NSDictionary *post in [data copy]) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(_backgroundQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            NSDictionary *images = post[@"images"];
            NSDictionary *lowRes = images[@"low_resolution"];
            NSDictionary *standard = images[@"standard_resolution"];
            NSDictionary *thumbnail = images[@"thumbnail"];
            
            NSDictionary *caption = post[@"caption"];
            NSDictionary *user = post[@"user"];
            
            PDKSelfie *selfie = [PDKSelfie new];
            selfie.userName = user[@"username"];
            selfie.fullName = user[@"full_name"];

            if (![caption isKindOfClass:[NSNull class]]) {
                selfie.caption = caption[@"text"];
                selfie.link = caption[@"link"];
            }
            selfie.standard = [PDKSelfiePic new];
            selfie.standard.height = standard[@"height"];
            selfie.standard.width = standard[@"width"];
            selfie.standard.url = standard[@"url"];

            selfie.lowRes = [PDKSelfiePic new];
            selfie.lowRes.height = lowRes[@"height"];
            selfie.lowRes.width = lowRes[@"width"];
            NSString *lowResurl = lowRes[@"url"];
            selfie.lowRes.url = lowResurl;
            selfie.lowRes.image = [strongSelf getImageFromURL:lowResurl];

            selfie.thumbnail = [PDKSelfiePic new];
            selfie.thumbnail.height = thumbnail[@"height"];
            selfie.thumbnail.width = thumbnail[@"width"];
            selfie.thumbnail.url = thumbnail[@"url"];
            NSString *thumbnailurl = thumbnail[@"url"];
            selfie.thumbnail.url = thumbnailurl;
            selfie.thumbnail.image = [strongSelf getImageFromURL:thumbnailurl];
            
            if (![selfie.caption isEqualToString:@"#dm #selfie #girl"]) {   // Get rid of a bit of spam
                [_collection addObject:selfie];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"gotSelfie" object:nil];
                });
            }
        });
    }
}

#pragma mark - Download and return image file
-(UIImage *)getImageFromURL:(NSString *)url
{
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
//    NSLog(@"size: %lu url:%@", (unsigned long)data.length, url);
    return [UIImage imageWithData:data];
}
@end
