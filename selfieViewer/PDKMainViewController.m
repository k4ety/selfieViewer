//
//  MainViewController.m
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#define TAG @"selfie"

#import "PDKMainViewController.h"
#import "PDKInstagramStore.h"
#import "PDKCollectionViewCell.h"
#import "PDKEnlargeViewController.h"

@interface PDKMainViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) PDKInstagramStore *instagram;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
@end

@implementation PDKMainViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    _backgroundQueue = dispatch_queue_create("com.k4ety.selfieViewer.queue", DISPATCH_QUEUE_CONCURRENT);
    _instagram = [PDKInstagramStore sharedStore];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundView.backgroundColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(displaySelfies)
                                                 name:@"gotSelfie"
                                               object:nil];
    if (!_instagram.accessToken) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(gotUserToken)
                                                     name:@"gotUserToken"
                                                   object:nil];
        [_instagram getAuth:self.view];
    } else {
        if (!_instagram.collection.count) {
            [_instagram getPicsWithTag:TAG];
        } else {
            [_instagram getMorePics];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)gotUserToken
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"gotUserToken"
                                                  object:nil];
    [_instagram getPicsWithTag:TAG];
}

-(void)displaySelfies
{
    [_collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    _collectionView.dataSource = nil;
    _collectionView.delegate = nil;
//    [_collectionView deleteSections:[NSIndexSet indexSetWithIndex:0]];
    [_instagram.collection removeAllObjects];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView reloadData];
}


#pragma mark - <UICollectionViewDataSource> methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _instagram.collection.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
// Pattern = Large, Small, Small
    NSString *reuseID;
    int type = (indexPath.row + 3) % 3;
//    NSLog(@"row = %ld, type = %d", (long)indexPath.row, type);
    if ( type == 0) {
        reuseID = @"largeID";
    } else reuseID = @"smallID";
    
    long row = indexPath.row;
    long max = _instagram.collection.count - 50;
    if (row > max) {
        [_instagram getMorePics];
    }
    
    PDKCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
    cell.selfie = _instagram.collection[indexPath.row];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


#pragma mark - <UICollectionViewDelegate> methods
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    PDKCollectionViewCell *cell = (PDKCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (!cell.selfie.standard.image) {
        dispatch_async(_backgroundQueue, ^{
            cell.selfie.standard.image = [_instagram getImageFromURL:cell.selfie.standard.url];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"gotImage" object:nil];
            });
        });
    }
    return YES;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PDKEnlargeViewController *enlargeVC = (PDKEnlargeViewController *)[segue destinationViewController];
    PDKCollectionViewCell *cell = sender;
    PDKSelfie *selfie = cell.selfie;
    enlargeVC.selfie = selfie;
//    NSArray *tags = [selfie.caption componentsSeparatedByString:@"#"];
//    NSLog(@"\nselfie: %@\n  %@\n  %@\n  %@\n  %lu\n", selfie.userName, selfie.fullName, selfie.caption, selfie.link, (unsigned long)tags.count);
}
@end
