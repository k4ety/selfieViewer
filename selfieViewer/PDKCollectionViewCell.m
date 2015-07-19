//
//  PDKCollectionViewCell.m
//  selfieViewer
//
//  Created by Paul King on 7/18/15.
//  Copyright (c) 2015 Paul King. All rights reserved.
//

#import "PDKCollectionViewCell.h"
#import "PDKSelfie.h"

@implementation PDKCollectionViewCell

- (void)setSelfie:(PDKSelfie *)selfie
{
    _selfie = selfie;
    if ([self.reuseIdentifier isEqualToString:@"smallID"]) {
        _imageView.image = selfie.thumbnail.image;
    }
    if ([self.reuseIdentifier isEqualToString:@"largeID"]) {
        _imageView.image = selfie.lowRes.image;
    }
}
@end
