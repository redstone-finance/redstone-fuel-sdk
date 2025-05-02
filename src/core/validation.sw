library;

use ::core::errors::*;

const MAX_DATA_TIMESTAMP_DELAY_SECONDS = 60;
const MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 60;
pub fn validate_timestamp(timestamp: u64, block_timestamp: u64) {
    if (block_timestamp > timestamp) {
        require(
            block_timestamp - timestamp <= MAX_DATA_TIMESTAMP_DELAY_SECONDS * 1000,
            RedStoneError::TimestampOutOfRange((false, block_timestamp, timestamp)),
        );
    }

    if (timestamp > block_timestamp) {
        require(
            timestamp - block_timestamp <= MAX_DATA_TIMESTAMP_AHEAD_SECONDS * 1000,
            RedStoneError::TimestampOutOfRange((true, block_timestamp, timestamp)),
        );
    }
}

const BASE_TS = 168_000_000_000;

#[test]
fn test_validate_proper_timestamps() {
    let mut i = 0;

    while (i < 2) {
        validate_timestamp(BASE_TS - MAX_DATA_TIMESTAMP_DELAY_SECONDS + i, BASE_TS);
        validate_timestamp(BASE_TS + MAX_DATA_TIMESTAMP_AHEAD_SECONDS - i, BASE_TS);

        i += 1;
    }
}

#[test(should_revert)]
fn test_validate_wrong_future_timestamp() {
    validate_timestamp(
        BASE_TS + MAX_DATA_TIMESTAMP_AHEAD_SECONDS * 1000 + 1,
        BASE_TS,
    );
}

#[test(should_revert)]
fn test_validate_wrong_past_timestamp() {
    validate_timestamp(
        BASE_TS - MAX_DATA_TIMESTAMP_DELAY_SECONDS * 1000 - 1,
        BASE_TS,
    );
}
