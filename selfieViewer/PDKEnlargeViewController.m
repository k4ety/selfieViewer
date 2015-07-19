//
//  PDKEnlargeViewController.m
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#define MINIMUM_SCALE 0.5
#define MAXIMUM_SCALE 6.0

#import "PDKEnlargeViewController.h"
#import "PDKSelfie.h"

@interface PDKEnlargeViewController () <UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property UITapGestureRecognizer *tapRecognizer;
@property UIPanGestureRecognizer *panRecognizer;
@property UIPinchGestureRecognizer *pinchRecognizer;
@property CGPoint translation;
@end

@implementation PDKEnlargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [_tapRecognizer setDelegate:self];
    _tapRecognizer.cancelsTouchesInView= NO;
    [self.view addGestureRecognizer:_tapRecognizer];

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [_panRecognizer setDelegate:self];
    _panRecognizer.cancelsTouchesInView= NO;
    [self.view addGestureRecognizer:_panRecognizer];
    
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [_pinchRecognizer setDelegate:self];
    _pinchRecognizer.cancelsTouchesInView= NO;
    [self.view addGestureRecognizer:_pinchRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!_selfie.standard.image) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewDidAppear:)
                                                     name:@"gotImage"
                                                   object:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    _imageView.image = _selfie.standard.image;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)tap:(id)sender
{
//    NSLog(@"Tap");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)pan:(UIPanGestureRecognizer *)gesture {
    static CGPoint currentTranslation;
    static CGFloat currentScale = 0;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        currentTranslation = _translation;
        currentScale = self.view.frame.size.width / self.view.bounds.size.width;
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateChanged) {

        CGPoint translation = [gesture translationInView:self.view];

        _translation.x = translation.x + currentTranslation.x;
        _translation.y = translation.y + currentTranslation.y;
        CGAffineTransform transform1 = CGAffineTransformMakeTranslation(_translation.x , _translation.y);
        CGAffineTransform transform2 = CGAffineTransformMakeScale(currentScale, currentScale);
        CGAffineTransform transform = CGAffineTransformConcat(transform1, transform2);
        self.view.transform = transform;
    }
}

// http://stackoverflow.com/questions/500027/how-to-zoom-in-out-an-uiimage-object-when-user-pinches-screen
- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateChanged) {
//        NSLog(@"gesture.scale = %f", gesture.scale);
        
        CGFloat currentScale = self.view.frame.size.width / self.view.bounds.size.width;
        CGFloat newScale = currentScale * gesture.scale;
        
        if (newScale < MINIMUM_SCALE) {
            newScale = MINIMUM_SCALE;
        }
        if (newScale > MAXIMUM_SCALE) {
            newScale = MAXIMUM_SCALE;
        }
        
        CGAffineTransform transform1 = CGAffineTransformMakeTranslation(_translation.x, _translation.y);
        CGAffineTransform transform2 = CGAffineTransformMakeScale(newScale, newScale);
        CGAffineTransform transform = CGAffineTransformConcat(transform1, transform2);
        self.view.transform = transform;
        gesture.scale = 1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
