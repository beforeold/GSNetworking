//
//  AnimatingRequestAccessory.h
//  Ape_uni
//
//  Created by BRBR on 10/30/14.
//  Copyright (c) 2014 BRBR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GSRootRequest.h"

@interface GSAnimatingRequestAccessory : NSObject <GSRequestAccessory>

@property(nonatomic, weak) UIView *animatingView;

@property(nonatomic, copy) NSString *animatingText;

- (id)initWithAnimatingView:(UIView *)animatingView;

- (id)initWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText;

+ (id)accessoryWithAnimatingView:(UIView *)animatingView;

+ (id)accessoryWithAnimatingView:(UIView *)animatingView animatingText:(NSString *)animatingText;

@end
