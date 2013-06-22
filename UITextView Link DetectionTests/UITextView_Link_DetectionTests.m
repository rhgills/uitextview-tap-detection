//
//  UITextView_Link_DetectionTests.m
//  UITextView Link DetectionTests
//
//  Created by Robert on 6/22/13.
//  Copyright (c) 2013 Robert Gilliam. All rights reserved.
//

#import "UITextView_Link_DetectionTests.h"

#import "UITextView+RSExtras.h"
#import "NSString+RSExtras.h"

#import <OCMock.h>
#define HC_SHORTHAND
#import <OCHamcrest.h>

#import <CoreGraphics/CoreGraphics.h>


@interface FakeTextRange : UITextRange

@property (readwrite, nonatomic) UITextPosition *end;

@end

@implementation FakeTextRange

@synthesize end = _end;

@end



@implementation UITextView_Link_DetectionTests {
    UITextView *textView;
    id fakeTextView;
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    textView = [[UITextView alloc] initWithFrame:CGRectZero];
    fakeTextView = [OCMockObject partialMockForObject:textView];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

#pragma mark - Test rs_linkAtPoint (testing potentialLinkIsEmpty. linkFromPotentialLink implicity)
/** 
 These tests are good, and can test the potentialLinkIsEmpty method implicitly. That means
 that that method is OK to be a private helper.
 */
- (void)testNoLinkIfNoPotentialLink
{
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:nil] rs_potentialLinkAtPoint:point];
    
    NSString *link = [textView rs_linkAtPoint:point];
    STAssertNil(link, nil);
}

- (void)testNoLinkIfEmptyPotentialLink
{
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:@""] rs_potentialLinkAtPoint:point];
    
    NSString *link = [textView rs_linkAtPoint:point];
    STAssertNil(link, nil);
}

- (void)testNoLinkIfNoActualLinks
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:point];
    
    [[[fakePotentialLink stub] andReturn:nil] rs_links];
    NSString *link = [textView rs_linkAtPoint:point];
    
    STAssertNil(link, nil);
}

- (void)testNoLinkIfZeroActualLinks
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    
    CGPoint point = CGPointZero;
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:point];
    
    [[[fakePotentialLink stub] andReturn:@[]] rs_links];
    NSString *link = [textView rs_linkAtPoint:point];
    
    STAssertNil(link, nil);
}

- (void)testLinkIsFirstActualLink
{
    NSString *potentialLink = @"example.com";
    id fakePotentialLink = [OCMockObject partialMockForObject:potentialLink];
    
    [[[fakeTextView stub] andReturn:fakePotentialLink] rs_potentialLinkAtPoint:CGPointZero];
    
    [[[fakePotentialLink stub] andReturn:@[@"first", @"second"]] rs_links];
    NSString *link = [textView rs_linkAtPoint:CGPointZero];
    
    STAssertEqualObjects(link, @"first", nil);
}


#pragma mark - Test Potential Link at Point
// possible refactoring generalization: contingous block of text/a word detection!
- (void)testNoPotentialLinkIfAtEndOfDocumentShorter
{
    CGPoint pointAtEndOfDocument = CGPointZero;
    [[[fakeTextView stub] andReturn:nil] closestPositionNotAtEndOfDocumentToPoint:pointAtEndOfDocument];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:pointAtEndOfDocument];
    
    assertThatInteger([potentialLink length], equalToInteger(0)); // a little coupled to implementation? nil or empty is OK
}

// test closestPosition
- (void)testClosestPositionToEndOfDocumentNotAtEndOfDocumentIsClosestPosition
{
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){NO})] characterAtPositionIsLastCharacterInDocument:CGPointZero];
    
    id closestPosition = [self newMock];
    [[[fakeTextView stub] andReturn:closestPosition] closestPositionToPoint:CGPointZero];
    
    assertThat([textView closestPositionNotAtEndOfDocumentToPoint:CGPointZero], sameInstance(closestPosition));
}

- (void)testNoClosestPositionNotAtEndOfDocumentIfAtEndOfDocument
{
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] characterAtPositionIsLastCharacterInDocument:CGPointZero];

    assertThat([textView closestPositionNotAtEndOfDocumentToPoint:CGPointZero], nilValue());
}

- (void)testCharacterAtPositionIsLastInDocument
{
    id endOfDocumentPosition = [self newMock];
    
    id textRange = [OCMockObject mockForClass:[UITextRange class]];
    [[[textRange stub] andReturn:endOfDocumentPosition] end];
    
    [[[fakeTextView stub] andReturn:textRange] characterRangeAtPoint:CGPointZero];
    
    [[[fakeTextView stub] andReturn:endOfDocumentPosition] endOfDocument];
    
    assertThatBool([textView characterAtPositionIsLastCharacterInDocument:CGPointZero], equalToBool(YES));
}

- (void)testCharacterAtPositionIsNotLastInDocument
{
    id endOfDocumentPosition = [self newMock];
    id otherTextPosition = [self newMock];
    
    id textRange = [OCMockObject mockForClass:[UITextRange class]];
    [[[textRange stub] andReturn:otherTextPosition] end];
    
    [[[fakeTextView stub] andReturn:textRange] characterRangeAtPoint:CGPointZero];
    
    [[[fakeTextView stub] andReturn:endOfDocumentPosition] endOfDocument];
    
    assertThatBool([textView characterAtPositionIsLastCharacterInDocument:CGPointZero], equalToBool(NO));
}

// isEmpty HCMatcher
// if count or length is responded to and is 0, or if nil - isEmpty
// if both responded to, undefined - throw to warn

// alternately: isEmptyCollection, isEmptyString() or nil?

- (void)testNoPotentialLinkIfAtEndOfDocument
{
    UITextPosition *documentEndPosition = [[UITextPosition alloc] init];
    
    FakeTextRange *textRangeEndingAtDocumentEnd = [[FakeTextRange alloc] init];
    textRangeEndingAtDocumentEnd.end = documentEndPosition;
    
    [[[fakeTextView stub] andReturn:textRangeEndingAtDocumentEnd] characterRangeAtPoint:CGPointZero];
    [[[fakeTextView stub] andReturn:documentEndPosition] endOfDocument];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:CGPointZero];
    
    assertThatInteger([potentialLink length], equalToInteger(0));
}

- (void)testEmptyPotentialLinkIfNoTextClosestToTapPoint
{
    CGPoint tapPoint = CGPointZero;
    
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] characterAtPositionIsLastCharacterInDocument:tapPoint];
    
    [[[fakeTextView stub] andReturn:nil] closestPositionToPoint:tapPoint];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThatInteger([potentialLink length], equalToInteger(0)); // greater coupling than preferred to if it returns nil or length 0, which are both OK from the spec
}

- (UITextPosition *)newTextPosition
{
    return [[UITextPosition alloc] init];
}

- (OCMockObject *)newMock
{
    return [OCMockObject mockForClass:[NSObject class]];
}

- (void)testNoPotentialLinkIfFirstCharacterCfOrLf
{
    [[fakeTextView stub] closestPositionNotAtEndOfDocumentToPoint:CGPointZero];
    [[[fakeTextView stub] andReturnValue:OCMOCK_VALUE((BOOL){YES})] firstCharacterIsCrOrLf:nil];
    
    assertThat([textView rs_potentialLinkAtPoint:CGPointZero], nilValue());
}

// compare to above
- (void)testNoPotentialLinkIfFirstCharacterNewline
{
    id position0 = [self newTextPosition];
    CGPoint tapPoint = CGPointZero;
    
    
    [[[fakeTextView stub] andReturn:position0] closestPositionNotAtEndOfDocumentToPoint:tapPoint];
    NSArray *charactersToTheRight = @[@"\n", @"a", @"b"];
    
    id range = [self newMock];
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
     [[[tokenizer stub] andReturn:range] rangeEnclosingPosition:position0 withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[fakeTextView stub] andReturn:charactersToTheRight[0]] textInRange:range];

    

    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThat(potentialLink, nilValue());
}

- (void)testCharacterAtPosition
{
    id position = [self newTextPosition];
    
    id range = [self newMock];
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
    [[[tokenizer stub] andReturn:range] rangeEnclosingPosition:position withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[fakeTextView stub] andReturn:@"a"] textInRange:range];
    
    
    assertThat([textView characterAtPosition:position], equalTo(@"a"));
}

- (void)testCrRecognized
{
    id position = [self newMock];
    
    NSString *cr = @"\n";
    [[[fakeTextView stub] andReturn:cr] characterAtPosition:position];
    
    STAssertTrue([textView firstCharacterIsCrOrLf:position], nil);
}

- (void)testLfRecognized
{
    id position = [self newMock];
    
    NSString *lf = @"\r";
    [[[fakeTextView stub] andReturn:lf] characterAtPosition:position];
    
    STAssertTrue([textView firstCharacterIsCrOrLf:position], nil);
}

- (void)testOtherCharacterOK
{
    id position = [self newMock];
    
    NSString *a = @"a";
    [[[fakeTextView stub] andReturn:a] characterAtPosition:position];
    
    STAssertFalse([textView firstCharacterIsCrOrLf:position], nil);
}



- (void)testDetectsPortionOfWordToTheRightOfTapPosition
{
    // actual
    id position0 = [self newTextPosition];
    CGPoint tapPoint = CGPointZero;
    

    [[[fakeTextView stub] andReturn:position0] closestPositionNotAtEndOfDocumentToPoint:tapPoint];
    
    
    // actual relevant parts
    NSArray *charactersToTheRight = @[@"a", @"b", @"c"];
    
    NSArray *ranges = @[[self newMock], [self newMock], [self newMock]];
    

    id position1 = [self newTextPosition];
    id position2 = [self newTextPosition];
    NSArray *positions = @[position0, position1, position2];
    
    // nextPosition for the position at that array
    NSArray *nextPosition = @[position1, position2];
    
    // rangeEnclosingPosition returns a different UITextRange for each character.
    // each range will return the character from textInRange:rangeOfChracter
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
    [[[tokenizer stub] andReturn:ranges[0]] rangeEnclosingPosition:positions[0] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[1]] rangeEnclosingPosition:positions[1] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[2]] rangeEnclosingPosition:positions[2] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    
    [[[fakeTextView stub] andReturn:charactersToTheRight[0]] textInRange:ranges[0]];
    [[[fakeTextView stub] andReturn:charactersToTheRight[1]] textInRange:ranges[1]];
    [[[fakeTextView stub] andReturn:charactersToTheRight[2]] textInRange:ranges[2]];
    
    [[[fakeTextView stub] andReturn:nextPosition[0]] positionFromPosition:position0 offset:1];
    [[[fakeTextView stub] andReturn:nextPosition[1]] positionFromPosition:position1 offset:1];
    [[[fakeTextView stub] andReturn:nil] positionFromPosition:position2 offset:1];
    
    // stubs to handle moving left!
    [[fakeTextView stub] appendToString:(id)anything() byMovingLeftFromAndNotIncludingTextPosition:(id)anything()];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThat(potentialLink, equalTo(@"abc"));
}

- (void)testDetectsPortionOfWordToTheLeftOfTapPosition
{
    // actual
    id position0 = [self newTextPosition];
    CGPoint tapPoint = CGPointZero;
    
    
    [[[fakeTextView stub] andReturn:position0] closestPositionNotAtEndOfDocumentToPoint:tapPoint];
    
    
    // actual relevant parts
//    NSString *string = @"cba"; // where a is the start position, and handled by right
    NSArray *charactersToTheLeft = @[@"a", @"b", @"c"]; // a is handled by right!
    
    NSArray *ranges = @[[self newMock], [self newMock], [self newMock]];
    
    
    id position1 = [self newTextPosition];
    id position2 = [self newTextPosition];
    NSArray *positions = @[position0, position1, position2];
    
    // nextPosition for the position at that array
    NSArray *nextPosition = @[position1, position2];
    
    // rangeEnclosingPosition returns a different UITextRange for each character.
    // each range will return the character from textInRange:rangeOfChracter
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
    [[[tokenizer stub] andReturn:ranges[0]] rangeEnclosingPosition:positions[0] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[1]] rangeEnclosingPosition:positions[1] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[2]] rangeEnclosingPosition:positions[2] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    
    [[[fakeTextView stub] andReturn:charactersToTheLeft[0]] textInRange:ranges[0]];
    [[[fakeTextView stub] andReturn:charactersToTheLeft[1]] textInRange:ranges[1]];
    [[[fakeTextView stub] andReturn:charactersToTheLeft[2]] textInRange:ranges[2]];
    
    [[[fakeTextView stub] andReturn:nextPosition[0]] positionFromPosition:position0 offset:-1];
    [[[fakeTextView stub] andReturn:nextPosition[1]] positionFromPosition:position1 offset:-1];
    [[[fakeTextView stub] andReturn:nil] positionFromPosition:position2 offset:-1];
    
    // stubs to handle moving right!
    [[fakeTextView stub] appendToString:(id)anything() byMovingRightFromAndIncludingTextPosition:(id)anything()];
    
    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThat(potentialLink, equalTo(@"cb"));
}

- (void)combinesLeftAndRight
{
    // stubs to handle moving right!
    [[[fakeTextView stub] andDo:^(NSInvocation *invocation) {
        NSMutableString *mutableString;
        [invocation getArgument:&mutableString atIndex:2];
        
        [mutableString appendString:@"cdef"];
    }] appendToString:(id)anything() byMovingRightFromAndIncludingTextPosition:(id)anything()];
    
    
    // actual
    id position0 = [self newTextPosition];
    CGPoint tapPoint = CGPointZero;
    
    
    [[[fakeTextView stub] andReturn:position0] closestPositionNotAtEndOfDocumentToPoint:tapPoint];
    
    
    // actual relevant parts
    //    NSString *string = @"abc"; // where c is the start position, and handled by right
    NSArray *charactersToTheLeft = @[@"c", @"b", @"a"]; // a is handled by right!
    
    NSArray *ranges = @[[self newMock], [self newMock], [self newMock]];
    
    
    id position1 = [self newTextPosition];
    id position2 = [self newTextPosition];
    NSArray *positions = @[position0, position1, position2];
    
    // nextPosition for the position at that array
    NSArray *nextPosition = @[position1, position2];
    
    // rangeEnclosingPosition returns a different UITextRange for each character.
    // each range will return the character from textInRange:rangeOfChracter
    
    id tokenizer = [OCMockObject mockForProtocol:@protocol(UITextInputTokenizer)];
    [[[fakeTextView stub] andReturn:tokenizer] tokenizer];
    
    [[[tokenizer stub] andReturn:ranges[0]] rangeEnclosingPosition:positions[0] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[1]] rangeEnclosingPosition:positions[1] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    [[[tokenizer stub] andReturn:ranges[2]] rangeEnclosingPosition:positions[2] withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    
    [[[fakeTextView stub] andReturn:charactersToTheLeft[0]] textInRange:ranges[0]];
    [[[fakeTextView stub] andReturn:charactersToTheLeft[1]] textInRange:ranges[1]];
    [[[fakeTextView stub] andReturn:charactersToTheLeft[2]] textInRange:ranges[2]];
    
    [[[fakeTextView stub] andReturn:nextPosition[0]] positionFromPosition:position0 offset:-1];
    [[[fakeTextView stub] andReturn:nextPosition[1]] positionFromPosition:position1 offset:-1];
    [[[fakeTextView stub] andReturn:nil] positionFromPosition:position2 offset:-1];
    

    NSString *potentialLink = [textView rs_potentialLinkAtPoint:tapPoint];
    assertThat(potentialLink, equalTo(@"abcdef"));
}

// first chracter is \n or \r, no potential link

// stops at character not allowed as part of link (nil, empty, whitespace or newline member)

// stops at no next position (how does api behave if tokenizer rangeEnclosingPosition: passed a nil?)



// - (void)testDetectsPortionOfWordToTheRightOfTextPosition
// - (void)testDetectsWordOnBothSidesOfTapPosition

@end


