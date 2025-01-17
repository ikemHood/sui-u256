/// Module: u256
module u256::u256 {
    use std::bcs;

    // Errors.
    /// When can't cast `U256` to `u128` (e.g. number too large).
    const ECAST_OVERFLOW: u64 = 0;

    /// When trying to get or put word into U256 but it's out of index.
    const EWORDS_OVERFLOW: u64 = 1;

    /// When math overflows.
    const EOVERFLOW: u64 = 2;

    /// When attempted to divide by zero.
    const EDIV_BY_ZERO: u64 = 3;

    /// When trying to call `from_bytes` on a vector of length != 32.
    const EVECTOR_LENGTH_NOT_32_BYTES: u64 = 4;

    // Constants.

    /// Max `u64` value.
    const U64_MAX: u128 = 18446744073709551615;

    /// Max `u128` value.
    const U128_MAX: u128 = 340282366920938463463374607431768211455;

    /// Total words in `U256` (64 * 4 = 256).
    const WORDS: u64 = 4;

    /// When both `U256` equal.
    const EQUAL: u8 = 0;

    /// When `a` is less than `b`.
    const LESS_THAN: u8 = 1;

    /// When `b` is greater than `b`.
    const GREATER_THAN: u8 = 2;

    // Data structs.

    /// The `U256` resource.
    /// Contains 4 u64 numbers.
    public struct U256 has copy, drop, store {
        v0: u64,
        v1: u64,
        v2: u64,
        v3: u64,
    }

    /// Double `U256` used for multiple (to store overflow).
    public struct DU256 has copy, drop, store {
        v0: u64,
        v1: u64,
        v2: u64,
        v3: u64,
        v4: u64,
        v5: u64,
        v6: u64,
        v7: u64,
    }

    // Public functions.

    /// Adds two `U256` and returns sum.
    public fun add(a: U256, b: U256): U256 {
        let mut ret = zero();
        let mut carry = 0u64;

        let mut i = 0;
        while (i < WORDS) {
            let a1 = get(&a, i);
            let b1 = get(&b, i);

            if (carry != 0) {
                let (res1, is_overflow1) = overflowing_add(a1, b1);
                let (res2, is_overflow2) = overflowing_add(res1, carry);
                put(&mut ret, i, res2);

                carry = 0;
                if (is_overflow1) {
                    carry = carry + 1;
                };

                if (is_overflow2) {
                    carry = carry + 1;
                }
            } else {
                let (res, is_overflow) = overflowing_add(a1, b1);
                put(&mut ret, i, res);

                carry = 0;
                if (is_overflow) {
                    carry = 1;
                };
            };

            i = i + 1;
        };

        assert!(carry == 0, EOVERFLOW);

        ret
    }

    /// Convert `U256` to `u128` value if possible (otherwise it aborts).
    public fun as_u128(a: U256): u128 {
        assert!(a.v2 == 0 && a.v3 == 0, ECAST_OVERFLOW);
        ((a.v1 as u128) << 64) + (a.v0 as u128)
    }

    /// Convert `U256` to `u64` value if possible (otherwise it aborts).
    public fun as_u64(a: U256): u64 {
        assert!(a.v1 == 0 && a.v2 == 0 && a.v3 == 0, ECAST_OVERFLOW);
        a.v0
    }

    /// Compares two `U256` numbers.
    public fun compare(a: &U256, b: &U256): u8 {
        let mut i = WORDS;
        while (i > 0) {
            i = i - 1;
            let a1 = get(a, i);
            let b1 = get(b, i);

            if (a1 != b1) {
                if (a1 < b1) {
                    return LESS_THAN
                } else {
                    return GREATER_THAN
                }
            }
        };

        EQUAL
    }

    /// Returns a `U256` from `u64` value.
    public fun from_u64(val: u64): U256 {
        from_u128((val as u128))
    }

    /// Returns a `U256` from `u128` value.
    public fun from_u128(val: u128): U256 {
        let (a2, a1) = split_u128(val);

        U256 {
            v0: a1,
            v1: a2,
            v2: 0,
            v3: 0,
        }
    }

    /// Multiples two `U256`.
    public fun mul(a: U256, b: U256): U256 {
        let mut ret = DU256 {
            v0: 0,
            v1: 0,
            v2: 0,
            v3: 0,
            v4: 0,
            v5: 0,
            v6: 0,
            v7: 0,
        };

        let mut i = 0;
        while (i < WORDS) {
            let mut carry = 0u64;
            let b1 = get(&b, i);

            let mut j = 0;
            while (j < WORDS) {
                let a1 = get(&a, j);

                if (a1 != 0 || carry != 0) {
                    let (hi, low) = split_u128((a1 as u128) * (b1 as u128));

                    let overflow = {
                        let existing_low = get_d(&ret, i + j);
                        let (low, o) = overflowing_add(low, existing_low);
                        put_d(&mut ret, i + j, low);
                        if (o) {
                            1
                        } else {
                            0
                        }
                    };

                    carry = {
                        let existing_hi = get_d(&ret, i + j + 1);
                        let hi = hi + overflow;
                        let (hi, o0) = overflowing_add(hi, carry);
                        let (hi, o1) = overflowing_add(hi, existing_hi);
                        put_d(&mut ret, i + j + 1, hi);

                        if (o0 || o1) {
                            1
                        } else {
                            0
                        }
                    };
                };

                j = j + 1;
            };

            i = i + 1;
        };

        let (r, overflow) = du256_to_u256(ret);
        assert!(!overflow, EOVERFLOW);
        r
    }

    /// Subtracts two `U256`, returns result.
    public fun sub(a: U256, b: U256): U256 {
        let mut ret = zero();

        let mut carry = 0u64;

        let mut i = 0;
        while (i < WORDS) {
            let a1 = get(&a, i);
            let b1 = get(&b, i);

            if (carry != 0) {
                let (res1, is_overflow1) = overflowing_sub(a1, b1);
                let (res2, is_overflow2) = overflowing_sub(res1, carry);
                put(&mut ret, i, res2);

                carry = 0;
                if (is_overflow1) {
                    carry = carry + 1;
                };

                if (is_overflow2) {
                    carry = carry + 1;
                }
            } else {
                let (res, is_overflow) = overflowing_sub(a1, b1);
                put(&mut ret, i, res);

                carry = 0;
                if (is_overflow) {
                    carry = 1;
                };
            };

            i = i + 1;
        };

        assert!(carry == 0, EOVERFLOW);
        ret
    }

    /// Divide `a` by `b`.
    public fun div(mut a: U256, mut b: U256): U256 {
        let mut ret = zero();

        let a_bits = bits(&a);
        let b_bits = bits(&b);

        assert!(b_bits != 0, EDIV_BY_ZERO); // DIVIDE BY ZERO.
        if (a_bits < b_bits) {
            // Immidiatelly return.
            return ret
        };

        let mut shift = a_bits - b_bits;
        b = shl(b, (shift as u8));

        loop {
            let cmp = compare(&a, &b);
            if (cmp == GREATER_THAN || cmp == EQUAL) {
                let index = shift / 64;
                let m = get(&ret, index);
                let c = m | 1 << ((shift % 64) as u8);
                put(&mut ret, index, c);

                a = sub(a, b);
            };

            b = shr(b, 1);
            if (shift == 0) {
                break
            };

            shift = shift - 1;
        };

        ret
    }

    /// Shift right `a`  by `shift`.
    public fun shr(a: U256, shift: u8): U256 {
        let mut ret = zero();

        let word_shift = (shift as u64) / 64;
        let bit_shift = (shift as u64) % 64;

        let mut i = word_shift;
        while (i < WORDS) {
            let m = get(&a, i) >> (bit_shift as u8);
            put(&mut ret, i - word_shift, m);
            i = i + 1;
        };

        if (bit_shift > 0) {
            let mut j = word_shift + 1;
            while (j < WORDS) {
                let m = get(&ret, j - word_shift - 1) + (get(&a, j) << (64 - (bit_shift as u8)));
                put(&mut ret, j - word_shift - 1, m);
                j = j + 1;
            };
        };

        ret
    }

    /// Shift left `a` by `shift`.
    public fun shl(a: U256, shift: u8): U256 {
        let mut ret = zero();

        let word_shift = (shift as u64) / 64;
        let bit_shift = (shift as u64) % 64;

        let mut i = word_shift;
        while (i < WORDS) {
            let m = get(&a, i - word_shift) << (bit_shift as u8);
            put(&mut ret, i, m);
            i = i + 1;
        };

        if (bit_shift > 0) {
            let mut j = word_shift + 1;

            while (j < WORDS) {
                let m = get(&ret, j) + (get(&a, j - 1 - word_shift) >> (64 - (bit_shift as u8)));
                put(&mut ret, j, m);
                j = j + 1;
            };
        };

        ret
    }

    /// Returns `a` AND `b`.
    public fun and(a: &U256, b: &U256): U256 {
        let mut ret = zero();

        let mut i = 0;
        while (i < WORDS) {
            let m = get(a, i) & get(b, i);
            put(&mut ret, i, m);
            i = i + 1;
        };

        ret
    }

    /// Returns `a` OR `b`.
    public fun or(a: &U256, b: &U256): U256 {
        let mut ret = zero();

        let mut i = 0;
        while (i < WORDS) {
            let m = get(a, i) | get(b, i);
            put(&mut ret, i, m);
            i = i + 1;
        };

        ret
    }

    /// Returns `a` XOR `b`.
    public fun xor(a: &U256, b: &U256): U256 {
        let mut ret = zero();

        let mut i = 0;
        while (i < WORDS) {
            let m = get(a, i) ^ get(b, i);
            put(&mut ret, i, m);
            i = i + 1;
        };

        ret
    }

    /// Returns `U256` equals to zero.
    public fun zero(): U256 {
        U256 {
            v0: 0,
            v1: 0,
            v2: 0,
            v3: 0,
        }
    }

    public fun max(): U256 {
        U256 {
            v0: 0xffffffffffffffff,
            v1: 0xffffffffffffffff,
            v2: 0xffffffffffffffff,
            v3: 0xffffffffffffffff,
        }
    }

    public fun fields(val: U256): (u64, u64, u64, u64){
        (val.v0, val.v1, val.v2, val.v3)
    }

    /// Get bits used to store `a`.
    public fun bits(a: &U256): u64 {
        let mut i = 1;
        while (i < WORDS) {
            let a1 = get(a, WORDS - i);
            if (a1 > 0) {
                return ((0x40 * (WORDS - i + 1)) - (leading_zeros_u64(a1) as u64))
            };

            i = i + 1;
        };

        let a1 = get(a, 0);
        0x40 - (leading_zeros_u64(a1) as u64)
    }

    /// Get leading zeros of a binary representation of `a`.
    public fun leading_zeros_u64(a: u64): u8 {
        if (a == 0) {
            return 64
        };

        let a1 = a & 0xFFFFFFFF;
        let a2 = a >> 32;

        if (a2 == 0) {
            let mut bit = 32;

            while (bit >= 1) {
                let b = (a1 >> (bit-1)) & 1;
                if (b != 0) {
                    break
                };

                bit = bit - 1;
            };

            (32 - bit) + 32
        } else {
            let mut bit = 64;
            while (bit >= 1) {
                let b = (a >> (bit-1)) & 1;
                if (b != 0) {
                    break
                };
                bit = bit - 1;
            };

            64 - bit
        }
    }

    /// Similar to Rust `overflowing_add`.
    /// Returns a tuple of the addition along with a boolean indicating whether an arithmetic overflow would occur.
    /// If an overflow would have occurred then the wrapped value is returned.
    public fun overflowing_add(a: u64, b: u64): (u64, bool) {
        let a128 = (a as u128);
        let b128 = (b as u128);

        let r = a128 + b128;
        if (r > U64_MAX) {
            // overflow
            let overflow = r - U64_MAX - 1;
            ((overflow as u64), true)
        } else {
            (((a128 + b128) as u64), false)
        }
    }

    /// Similar to Rust `overflowing_sub`.
    /// Returns a tuple of the addition along with a boolean indicating whether an arithmetic overflow would occur.
    /// If an overflow would have occurred then the wrapped value is returned.
    public fun overflowing_sub(a: u64, b: u64): (u64, bool) {
        if (a < b) {
            let r = b - a;
            ((U64_MAX as u64) - r + 1, true)
        } else {
            (a - b, false)
        }
    }

    /// Extracts two `u64` from `a` `u128`.
    public fun split_u128(a: u128): (u64, u64) {
        let a1 = ((a >> 64) as u64);
        let a2 = ((a & 0xFFFFFFFFFFFFFFFF) as u64);

        (a1, a2)
    }

    /// Get word from `a` by index `i`.
    public fun get(a: &U256, i: u64): u64 {
        if (i == 0) {
            a.v0
        } else if (i == 1) {
            a.v1
        } else if (i == 2) {
            a.v2
        } else if (i == 3) {
            a.v3
        } else {
            abort EWORDS_OVERFLOW
        }
    }

    /// Get word from `DU256` by index.
    public fun get_d(a: &DU256, i: u64): u64 {
        if (i == 0) {
            a.v0
        } else if (i == 1) {
            a.v1
        } else if (i == 2) {
            a.v2
        } else if (i == 3) {
            a.v3
        } else if (i == 4) {
            a.v4
        } else if (i == 5) {
            a.v5
        } else if (i == 6) {
            a.v6
        } else if (i == 7) {
            a.v7
        } else {
            abort EWORDS_OVERFLOW
        }
    }

    /// Put new word `val` into `U256` by index `i`.
    public fun put(a: &mut U256, i: u64, val: u64) {
        if (i == 0) {
            a.v0 = val;
        } else if (i == 1) {
            a.v1 = val;
        } else if (i == 2) {
            a.v2 = val;
        } else if (i == 3) {
            a.v3 = val;
        } else {
            abort EWORDS_OVERFLOW
        }
    }

    /// Put new word into `DU256` by index `i`.
    public fun put_d(a: &mut DU256, i: u64, val: u64) {
        if (i == 0) {
            a.v0 = val;
        } else if (i == 1) {
            a.v1 = val;
        } else if (i == 2) {
            a.v2 = val;
        } else if (i == 3) {
            a.v3 = val;
        } else if (i == 4) {
            a.v4 = val;
        } else if (i == 5) {
            a.v5 = val;
        } else if (i == 6) {
            a.v6 = val;
        } else if (i == 7) {
            a.v7 = val;
        } else {
            abort EWORDS_OVERFLOW
        }
    }

    /// Convert `DU256` to `U256`.
    public fun du256_to_u256(a: DU256): (U256, bool) {
        let b = U256 {
            v0: a.v0,
            v1: a.v1,
            v2: a.v2,
            v3: a.v3,
        };

        let mut overflow = false;
        if (a.v4 != 0 || a.v5 != 0 || a.v6 != 0 || a.v7 != 0) {
            overflow = true;
        };

        (b, overflow)
    }

    /// Converts `vector<u8>` `a` to a `U256`.
    public fun from_bytes(a: &vector<u8>): U256 {
        assert!(vector::length(a) == 32, EVECTOR_LENGTH_NOT_32_BYTES);
        let mut ret = zero();
        put(&mut ret, 0, ((*vector::borrow(a, 0) as u64) << 7) + ((*vector::borrow(a, 1) as u64) << 6)
            + ((*vector::borrow(a, 2) as u64) << 5) + ((*vector::borrow(a, 3) as u64) << 4)
            + ((*vector::borrow(a, 4) as u64) << 3) + ((*vector::borrow(a, 5) as u64) << 2)
            + ((*vector::borrow(a, 6) as u64) << 1) + (*vector::borrow(a, 7) as u64));
        put(&mut ret, 1, ((*vector::borrow(a, 8) as u64) << 7) + ((*vector::borrow(a, 9) as u64) << 6)
            + ((*vector::borrow(a, 10) as u64) << 5) + ((*vector::borrow(a, 11) as u64) << 4)
            + ((*vector::borrow(a, 12) as u64) << 3) + ((*vector::borrow(a, 13) as u64) << 2)
            + ((*vector::borrow(a, 14) as u64) << 1) + (*vector::borrow(a, 15) as u64));
        put(&mut ret, 2, ((*vector::borrow(a, 16) as u64) << 7) + ((*vector::borrow(a, 17) as u64) << 6)
            + ((*vector::borrow(a, 18) as u64) << 5) + ((*vector::borrow(a, 19) as u64) << 4)
            + ((*vector::borrow(a, 20) as u64) << 3) + ((*vector::borrow(a, 21) as u64) << 2)
            + ((*vector::borrow(a, 22) as u64) << 1) + (*vector::borrow(a, 23) as u64));
        put(&mut ret, 3, ((*vector::borrow(a, 24) as u64) << 7) + ((*vector::borrow(a, 25) as u64) << 6)
            + ((*vector::borrow(a, 26) as u64) << 5) + ((*vector::borrow(a, 27) as u64) << 4)
            + ((*vector::borrow(a, 28) as u64) << 3) + ((*vector::borrow(a, 29) as u64) << 2)
            + ((*vector::borrow(a, 30) as u64) << 1) + (*vector::borrow(a, 31) as u64));
        ret
    }

    /// Converts `U256` `a` to a `vector<u8>`.
    public fun to_bytes(a: &U256): vector<u8> {
        let mut ret = vector::empty<u8>();
        vector::append(&mut ret, bcs::to_bytes(&get(a, 0)));
        vector::append(&mut ret, bcs::to_bytes(&get(a, 1)));
        vector::append(&mut ret, bcs::to_bytes(&get(a, 2)));
        vector::append(&mut ret, bcs::to_bytes(&get(a, 3)));
        ret
    }
}
