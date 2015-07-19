//
//  PDKCollectionViewCell.h
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PDKSelfie.h"

@interface PDKCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) PDKSelfie *selfie;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@end
