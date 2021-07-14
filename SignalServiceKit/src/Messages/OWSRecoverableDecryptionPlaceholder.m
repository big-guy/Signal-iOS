//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "OWSRecoverableDecryptionPlaceholder.h"
#import "TSThread.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation OWSRecoverableDecryptionPlaceholder

- (nullable instancetype)initWithFailedEnvelope:(SSKProtoEnvelope *)envelope
                                        groupId:(nullable NSData *)groupId
                                    transaction:(SDSAnyWriteTransaction *)writeTx
{
    SignalServiceAddress *sender = [[SignalServiceAddress alloc] initWithUuidString:envelope.sourceUuid];
    if (!sender) {
        OWSFailDebug(@"Invalid UUID");
        return nil;
    }

    TSThread *thread;
    if (groupId.length > 0) {
        thread = [TSGroupThread fetchWithGroupId:groupId transaction:writeTx];
        OWSAssertDebug(thread);
    }
    if (!thread) {
        thread = [TSContactThread getThreadWithContactAddress:sender transaction:writeTx];
        OWSAssertDebug(thread);
    }
    if (!thread) {
        return nil;
    }
    TSErrorMessageBuilder *builder = [TSErrorMessageBuilder errorMessageBuilderWithThread:thread errorType:TSErrorMessageDecryptionFailure];
    builder.timestamp = envelope.timestamp;
    builder.senderAddress = sender;

    return [super initErrorMessageWithBuilder:builder];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run
// `sds_codegen.sh`.

// clang-format off
// clang-format on

// --- CODE GENERATION MARKER

#pragma mark - Methods

- (BOOL)isVisible
{
    // Check if 60mins have elapsed
    NSDate *expiration = [self.receivedAtDate dateByAddingTimeInterval:kHourInterval];
    return [expiration isBeforeNow] || self.wasRead;
}

- (BOOL)supportsReplacement
{
    return !self.isVisible;
}

- (NSString *)previewTextWithTransaction:(SDSAnyReadTransaction *)transaction
{
    if (self.isVisible) {
        NSString *formatString = NSLocalizedString(
            @"ERROR_MESSAGE_DECRYPTION_FAILURE", @"Error message for a decryption failure. Embeds {{senders name}}.");

        NSString *senderName = [self.contactsManager shortDisplayNameForAddress:self.sender transaction:transaction];
        return [[NSString alloc] initWithFormat:formatString, senderName];
    } else {
        return @""; // Sender Key TODO: Should conversation list walk backwards to find the last interaction with a preview?
    }
}

@end

NS_ASSUME_NONNULL_END
