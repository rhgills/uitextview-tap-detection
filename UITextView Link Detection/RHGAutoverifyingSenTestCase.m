//
//  RHGAutoverifyingSenTestCase.m
//  Phoenix
//
//  Created by Robert Gilliam on 6/19/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import "RHGAutoverifyingSenTestCase.h"
#import <OCMockObject.h>


@interface RHGAutoverifyingSenTestCase ()

@property (nonatomic, strong) NSMutableArray *mocksToVerify;

@end




@implementation RHGAutoverifyingSenTestCase

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    for (id mock in self.mocksToVerify) {
        [mock verify];
    }
    self.mocksToVerify = nil;
    [super tearDown];
}

- (id)autoVerifiedMockForClass:(Class)aClass
{
    id mock = [OCMockObject mockForClass:aClass];
    [self verifyDuringTearDown:mock];
    return mock;
}

- (id)autoVerifiedPartialMockForObject:(id)object
{
    id mock = [OCMockObject partialMockForObject:object];
    [self verifyDuringTearDown:mock];
    return mock;
}

- (id)autoVerifiedMockForProtocol:(Protocol *)protocol
{
    id mock = [OCMockObject mockForProtocol:protocol];
    [self verifyDuringTearDown:mock];
    return mock;
}

- (void)verifyDuringTearDown:(id)mock
{
    if (self.mocksToVerify == nil) {
        self.mocksToVerify = [NSMutableArray array];
    }
    [self.mocksToVerify addObject:mock];
}


@end
