#import "NSString+RSExtras.h"

@implementation UITextView (RSExtras)


static BOOL stringCharacterIsAllowedAsPartOfLink(NSString *s) {

    /*[s length] is assumed to be 0 or 1. s may be nil.
     Totally not a strict check.*/

    if (s == nil || [s length] < 1)
        return NO;

    unichar ch = [s characterAtIndex:0];
    if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:ch])
        return NO;
    return YES;
}

- (UITextPosition *)closestPositionNotAtEndOfDocumentToPoint:(CGPoint)point
{
    // check for the character being the last character in the document
    UITextRange *textRange = [self characterRangeAtPoint:point];
    UITextPosition *endOfDocumentTextPosition = self.endOfDocument;
    if ([textRange.end isEqual:endOfDocumentTextPosition])
        return nil;
    
    // get the closest text position for the point
    UITextPosition *tapPosition = [self closestPositionToPoint:point];
    
    return tapPosition;
}

- (NSString *)rs_potentialLinkAtPoint:(CGPoint)point {

    /*Grow a string around the tap until hitting a space, cr, lf, or beginning or end of document.*/

    /*If we don't check for end of document, then you could tap way below end of text, and it would return a link if the last text was a link. This has the unfortunate side effect that you can't tap on the last character of a link if it appears at the end of a document. I can live with shipping that.*/


    UITextPosition *tapPosition = [self closestPositionNotAtEndOfDocumentToPoint:point];
    
    NSMutableString *s = [NSMutableString stringWithString:@""];

    /*Move right*/

    UITextPosition *textPosition = tapPosition;

    if ([self firstCharacterIsCrOrLf:textPosition]) {
        return nil;
    }
    
    [self appendToString:s byMovingRightFromTextPosition:textPosition];

    /*Move left*/
    [self handleMovingLeftTapPosition:tapPosition stringBuilder:s];
    
    return s;
}

- (BOOL)firstCharacterIsCrOrLf:(UITextPosition *)startingTextPosition
{
    UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:startingTextPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
    NSString *oneCharacter = [self textInRange:rangeOfCharacter];
    if ([oneCharacter isEqualToString:@"\n"] || [oneCharacter isEqualToString:@"\r"])
        return YES;

    return NO;
}

- (id)appendToString:(NSMutableString *)s byMovingRightFromTextPosition:(UITextPosition *)textPosition
{
    return [self appendToString:s
               byMovingByOffset:1
               fromTextPosition:textPosition];
}

- (id)appendToString:(NSMutableString *)s byMovingByOffset:(NSInteger)offset fromTextPosition:(UITextPosition *)textPosition
{
    while (true) {
        UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:textPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
        NSString *oneCharacter = [self textInRange:rangeOfCharacter];
        
        if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
            break;
        [self addCharacter:oneCharacter
         intoMutableString:s
atFrontOrBackDependingOnOffset:offset];
        
        textPosition = [self positionFromPosition:textPosition offset:offset];
        if (textPosition == nil)
            break;
    }
    
    return s;
}

- (void)addCharacter:(NSString *)oneCharacter intoMutableString:(NSMutableString *)s atFrontOrBackDependingOnOffset:(NSInteger)offset
{
    if (offset == 1) {
        [s appendString:oneCharacter];
    }else if( offset == -1) {
        [s insertString:oneCharacter atIndex:0];
    }
}

//[self appendToString:s
//    byMovingByOffset:-1
//    fromTextPosition:tapPosition];
- (void)handleMovingLeftTapPosition:(UITextPosition *)tapPosition stringBuilder:(NSMutableString *)s
{
    UITextPosition *textPosition = [self positionFromPosition:tapPosition offset:-1];
    if (textPosition != nil) {
        
        while (true) {
            UITextRange *rangeOfCharacter = [self.tokenizer rangeEnclosingPosition:textPosition withGranularity:UITextGranularityCharacter inDirection:UITextWritingDirectionNatural];
            NSString *oneCharacter = [self textInRange:rangeOfCharacter];
            
            if (!stringCharacterIsAllowedAsPartOfLink(oneCharacter))
                break;
            [s insertString:oneCharacter atIndex:0];
            
            textPosition = [self positionFromPosition:textPosition offset:-1];
            if (textPosition == nil)
                break;
        }
    }
}

- (NSString *)rs_linkAtPoint:(CGPoint)point {

    NSString *potentialLink = [self rs_potentialLinkAtPoint:point];
    if ([self potentialLinkIsEmpty:potentialLink]) {
        return nil;
    }

    return [self linkFromPotentialLink:potentialLink];
}

- (BOOL)potentialLinkIsEmpty:(NSString *)potentialLink
{
    if (potentialLink == nil || [potentialLink length] < 1)
        return YES;
    
    return NO;
}

- (NSString *)linkFromPotentialLink:(NSString *)potentialLink
{
    NSArray *links = [potentialLink rs_links];
    if (links == nil || [links count] < 1)
        return nil;
    
    NSString *firstLink = links[0];
    return firstLink;
}


@end