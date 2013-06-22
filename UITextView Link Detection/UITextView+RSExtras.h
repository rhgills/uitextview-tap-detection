//
//  UITextView+RSExtras2.h
//  UITextView Link Detection
//
//  Created by Robert on 6/22/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (RSExtras2)

- (NSString *)rs_potentialLinkAtPoint:(CGPoint)point;
- (NSString *)rs_linkAtPoint:(CGPoint)point;

// for tests
- (void)handleMovingLeftTapPosition:(UITextPosition *)tapPosition stringBuilder:(NSMutableString *)s;
- (UITextPosition *)closestPositionNotAtEndOfDocumentToPoint:(CGPoint)point;
- (id)appendToString:(NSMutableString *)s byMovingRightFromTextPosition:(UITextPosition *)textPosition;

@end
