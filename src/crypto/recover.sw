library;

use ::utils::bytes::*;
use std::{
    b512::*,
    bytes::*,
    bytes_conversions::b256::*,
    constants::ZERO_B256,
    ecr::{
        ec_recover,
        EcRecoverError,
    },
    hash::Hasher,
    logging::log,
    vm::evm::{
        ecr::ec_recover_evm_address,
        evm_address::EvmAddress,
    },
};
use ::utils::sample::{SAMPLE_ID_V27, SAMPLE_ID_V28, SampleDataPackage};

pub fn recover_signer_address(signature_bytes: Bytes, signable_bytes: Bytes) -> b256 {
    let (r_bytes, mut s_bytes) = signature_bytes.slice_tail_offset(32, 1);
    let v = signature_bytes.get(signature_bytes.len() - 1).unwrap();
    let r_number = b256::from_be_bytes(r_bytes);
    let s_number = b256::from_be_bytes(s_bytes);

    let mut hasher = Hasher::new();
    hasher.write(signable_bytes);
    let hash = hasher.keccak256();

    recover_public_address(r_number, s_number, v, hash).unwrap().bits()
}

fn recover_public_address(
    r: b256,
    s: b256,
    v: u8,
    msg_hash: b256,
) -> Result<EvmAddress, EcRecoverError> {
    let mut v_256: b256 = ZERO_B256;
    if (v == 28) {
        v_256 = 0x0000000000000000000000000000000000000000000000000000000000000001;
    }

    let mut s_with_parity = s | (v_256 << 255);

    let signature = B512::from((r, s_with_parity));

    ec_recover_evm_address(signature, msg_hash)
}

#[test]
fn test_recover_signer_address_v27() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V27);
    let result = recover_signer_address(sample.signature_bytes(), sample.signable_bytes);

    assert(sample.signer_address == result);
}

#[test]
fn test_recover_signer_address_v28() {
    let sample = SampleDataPackage::sample(SAMPLE_ID_V28);
    let result = recover_signer_address(sample.signature_bytes(), sample.signable_bytes);

    assert(sample.signer_address == result);
}
