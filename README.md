This repository is an integral part of the https://github.com/redstone-finance/redstone-oracles-monorepo repository,
especially of the `fuel-connector` package
(https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/fuel-connector)
and is subject of all their licenses.

## Usage

📟 Prerequisites: [Read how the RedStone Oracles work](https://docs.redstone.finance/docs/Introduction/).

Write the following to your `Forc.toml` file:

```toml
[dependencies]
redstone = { git = "https://github.com/redstone-finance/redstone-fuel-sdk", tag = "testnet-0.65.2" }
```

To process a RedStone payload (with the structure defined [here](hhttps://docs.redstone.finance/img/payload.png))
for a defined list of `feed_ids`, write the `.sw` file as follows:

```rust
library;

use std::{block::timestamp, bytes::Bytes};
use redstone::{core::config::Config, core::processor::process_input, utils::vec::*};

fn get_timestamp() -> u64 {
    timestamp() - (10 + (1 << 62))
}

fn process_payload(feed_ids: Vec<u256>, payload_bytes: Bytes) -> (Vec<u256>, u64) {
    let signers = Vec::<b256>::new().with(0x00000000000000000000000012470f7aba85c8b81d63137dd5925d6ee114952b); // for example, a Vec<b256> configured in the contract
    let signer_count_threshold = 1; // for example, a value configured in the contract
    let config = Config {
        feed_ids,
        signers,
        signer_count_threshold,
        block_timestamp: get_timestamp(),
    };

    process_input(payload_bytes, config)
}
```

Each item of `feed_ids` is a string encoded to `u256` which means, that's a value
consisting of hex-values of the particular letters in the string. For example:
`ETH` as a `u256` is `0x455448u256` in hex or `4543560` in decimal,
as `256*256*ord('E')+256*ord('T')+ord('H')`.
<br />
📟 To convert particular values, you can use the https://cairo-utils-web.vercel.app/ endpoint.<br />

The data packages transferred to the contract are being verified by signature checking.
To be counted to achieve the `signer_count_threshold`, the signer signing the passed data
should be one of the `signers` passed in the config.

The function returns a `Vec` of aggregated values of each feed passed as an identifier inside `feed_ids`
and the minimal data timestamp read from the payload_bytes.

### Sample contracts

See more
[here](https://github.com/redstone-finance/redstone-oracles-monorepo/blob/main/packages/fuel-connector/sway/contract/README.md)

## Docs

### Autogenerated

See [here](https://redstone-docs-git-fuel-docs-redstone-finance.vercel.app/sway/redstone/index.html)

### Library

#### Core

The main processor of the data

* the main entrypoint to the code: **process_input** inside [`processor.sw`](./src/core/processor.sw) file
  * it parses payload-bytes (`::from_bytes method`) to `DataPackages`, consisting of `DataPoints`,
  see: https://docs.redstone.finance/img/payload.png
* each `DataPackage` is signed by a signer, to be recovered having the `DataPackage`'s data and the signature
(both are included in the payload-bytes)
  * see recovering in the [`crypto`](#crypto) module, [`recover.sw`](./src/crypto/recover.sw)
* the recovering is important in the aggregation process: only the data signed by trusted signers (part of z `Config`)
are counted to the aggregation (median value), see [`config_validation.sw`](./src/core/config_validation.sw)
* it also validates timestamps (if they're not too old/far/future), [`validation.sw`](./src/core/validation.sw)
* the aggregation (median values) is based on building a matrix: for each `feed_id` (in rows) from the `Config` the
values for particular trusted signers in columns (taken by their indices), [`aggregation.sw`](./src/core/aggregation.sw)

#### Crypto

Crypto helpers

#### Protocol

* contains the structures (`Payload`, `DataPackage`, `DataPoint`) and their processing from bytes,
having the protocol constants defined (sizes of the values to be parsed), [`constants.sw`](./src/protocol/constants.sw)

#### Utils

Some important utils

* The most important part is obtaining a number (`u256` or `u64`) from bytes with the suitable byte size, regarding the protocol size constants, see: [`from_bytes_convertible.sw`](./src/utils/from_bytes_convertible.sw) and [`from_bytes.sw`](./src/utils/from_bytes.sw)
* There are also helpers:
  * for safe taking the average value of two numbers, see [`numbers.sw`](./src/utils/numbers.sw)
* And for vec operations (see: [`vec.sw`](./src/utils/vec.sw))
  * trimming data/numbers from the end of passed vector,
  * taking median values
  * finding a duplicate inside
  * sorting (not so optimal, bubble-sort, but we're expecting 3–5 values to be sorted)
* Sample/test helpers in [`sample`](./src/utils/sample.sw)
