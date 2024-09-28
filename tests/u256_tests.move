#[test_only]
module u256::u256_tests {
    use u256::u256::DU256;
    use u256::u256::{
        add, mul, sub, shr, shl, div, as_u64, 
        as_u128, from_u64, from_u128, compare, zero,
        bits, leading_zeros_u64, overflowing_add, split_u128,
        overflowing_sub, du256_to_u256, put_d, put, get, get_d,
    };

    // Constants.
    /// Max `u64` value.
    const U64_MAX: u128 = 18446744073709551615;

    /// Max `u128` value.
    const U128_MAX: u128 = 340282366920938463463374607431768211455;

    // const MAX_U256: u128 = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // #[test]
    // fun test_get_d() {
    //     let a =  DU256 {
    //         v0: 1,
    //         v1: 2,
    //         v2: 3,
    //         v3: 4,
    //         v4: 5,
    //         v5: 6,
    //         v6: 7,
    //         v7: 8,
    //     };

    //     assert!(get_d(&a, 0) == 1, 0);
    //     assert!(get_d(&a, 1) == 2, 1);
    //     assert!(get_d(&a, 2) == 3, 2);
    //     assert!(get_d(&a, 3) == 4, 3);
    //     assert!(get_d(&a, 4) == 5, 4);
    //     assert!(get_d(&a, 5) == 6, 5);
    //     assert!(get_d(&a, 6) == 7, 6);
    //     assert!(get_d(&a, 7) == 8, 7);
    // }

    // #[test]
    // #[expected_failure(abort_code = 1)]
    // fun test_get_d_overflow() {
    //     let a = DU256 {
    //         v0: 1,
    //         v1: 2,
    //         v2: 3,
    //         v3: 4,
    //         v4: 5,
    //         v5: 6,
    //         v6: 7,
    //         v7: 8,
    //     };

    //     get_d(&a, 8);
    // }

    // #[test]
    // fun test_put_d() {
    //     let mut a = DU256 {
    //         v0: 1,
    //         v1: 2,
    //         v2: 3,
    //         v3: 4,
    //         v4: 5,
    //         v5: 6,
    //         v6: 7,
    //         v7: 8,
    //     };

    //     put_d(&mut a, 0, 10);
    //     put_d(&mut a, 1, 20);
    //     put_d(&mut a, 2, 30);
    //     put_d(&mut a, 3, 40);
    //     put_d(&mut a, 4, 50);
    //     put_d(&mut a, 5, 60);
    //     put_d(&mut a, 6, 70);
    //     put_d(&mut a, 7, 80);

    //     assert!(get_d(&a, 0) == 10, 0);
    //     assert!(get_d(&a, 1) == 20, 1);
    //     assert!(get_d(&a, 2) == 30, 2);
    //     assert!(get_d(&a, 3) == 40, 3);
    //     assert!(get_d(&a, 4) == 50, 4);
    //     assert!(get_d(&a, 5) == 60, 5);
    //     assert!(get_d(&a, 6) == 70, 6);
    //     assert!(get_d(&a, 7) == 80, 7);
    // }

    // #[test]
    // #[expected_failure(abort_code = 1)]
    // fun test_put_d_overflow() {
    //     let mut a = DU256 {
    //         v0: 1,
    //         v1: 2,
    //         v2: 3,
    //         v3: 4,
    //         v4: 5,
    //         v5: 6,
    //         v6: 7,
    //         v7: 8,
    //     };

    //     put_d(&mut a, 8, 0);
    // }

    // #[test]
    // fun test_du256_to_u256() {
    //     let mut a = DU256 {
    //         v0: 255,
    //         v1: 100,
    //         v2: 50,
    //         v3: 300,
    //         v4: 0,
    //         v5: 0,
    //         v6: 0,
    //         v7: 0,
    //     };

    //     let (m, overflow) = du256_to_u256(a);
    //     assert!(!overflow, 0);
    //     assert!(m.v0 == a.v0, 1);
    //     assert!(m.v1 == a.v1, 2);
    //     assert!(m.v2 == a.v2, 3);
    //     assert!(m.v3 == a.v3, 4);

    //     a.v4 = 100;
    //     a.v5 = 5;

    //     let (m, overflow) = du256_to_u256(a);
    //     assert!(overflow, 5);
    //     assert!(m.v0 == a.v0, 6);
    //     assert!(m.v1 == a.v1, 7);
    //     assert!(m.v2 == a.v2, 8);
    //     assert!(m.v3 == a.v3, 9);
    // }

    #[test]
    fun test_get() {
        let a = from_u64(1);

        assert!(get(&a, 0) == 1, 0);
        assert!(get(&a, 1) == 2, 1);
        assert!(get(&a, 2) == 3, 2);
        assert!(get(&a, 3) == 4, 3);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_get_aborts() {
        let _ = get(&zero(), 4);
    }

    #[test]
    fun test_put() {
        let mut a = zero();
        put(&mut a, 0, 255);
        assert!(get(&a, 0) == 255, 0);

        put(&mut a, 1, (U64_MAX as u64));
        assert!(get(&a, 1) == (U64_MAX as u64), 1);

        put(&mut a, 2, 100);
        assert!(get(&a, 2) == 100, 2);

        put(&mut a, 3, 3);
        assert!(get(&a, 3) == 3, 3);

        put(&mut a, 2, 0);
        assert!(get(&a, 2) == 0, 4);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_put_overflow() {
        let mut a = zero();
        put(&mut a, 6, 255);
    }

    #[test]
    fun test_from_u128() {
        let mut i = 0;
        while (i < 1024) {
            let big = from_u128(i);
            assert!(as_u128(big) == i, 0);
            i = i + 1;
        };
    }

    #[test]
    fun test_add() {
        let mut a = from_u128(1000);
        let mut b = from_u128(500);

        let mut s = as_u128(add(a, b));
        assert!(s == 1500, 0);

        a = from_u128(U64_MAX);
        b = from_u128(U64_MAX);

        s = as_u128(add(a, b));
        assert!(s == (U64_MAX + U64_MAX), 1);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_add_overflow() {
        // let max = from_u64(U64_MAX as u64);

        let a = from_u64(1);

        let _ = add(a, from_u128(U64_MAX));
    }

    #[test]
    fun test_sub() {
        let a = from_u128(1000);
        let b = from_u128(500);

        let s = as_u128(sub(a, b));
        assert!(s == 500, 0);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_sub_overflow() {
        let a = from_u128(0);
        let b = from_u128(1);

        let _ = sub(a, b);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_too_big_to_cast_to_u128() {
        let a = from_u128(U128_MAX);
        let b = from_u128(U128_MAX);

        let _ = as_u128(add(a, b));
    }

    #[test]
    fun test_overflowing_add() {
        let (mut n, mut z) = overflowing_add(10, 10);
        assert!(n == 20, 0);
        assert!(!z, 1);

        (n, z) = overflowing_add((U64_MAX as u64), 1);
        assert!(n == 0, 2);
        assert!(z, 3);

        (n, z) = overflowing_add((U64_MAX as u64), 10);
        assert!(n == 9, 4);
        assert!(z, 5);

        (n, z) = overflowing_add(5, 8);
        assert!(n == 13, 6);
        assert!(!z, 7);
    }

    #[test]
    fun test_overflowing_sub() {
        let (mut n, mut z) = overflowing_sub(10, 5);
        assert!(n == 5, 0);
        assert!(!z, 1);

        (n, z) = overflowing_sub(0, 1);
        assert!(n == (U64_MAX as u64), 2);
        assert!(z, 3);

        (n, z) = overflowing_sub(10, 10);
        assert!(n == 0, 4);
        assert!(!z, 5);
    }

    #[test]
    fun test_split_u128() {
        let (mut a1, mut a2) = split_u128(100);
        assert!(a1 == 0, 0);
        assert!(a2 == 100, 1);

        (a1, a2) = split_u128(U64_MAX + 1);
        assert!(a1 == 1, 2);
        assert!(a2 == 0, 3);
    }

    #[test]
    fun test_mul() {
        let mut a = from_u128(285);
        let mut b = from_u128(375);

        let mut c = as_u128(mul(a, b));
        assert!(c == 106875, 0);

        a = from_u128(0);
        b = from_u128(1);

        c = as_u128(mul(a, b));

        assert!(c == 0, 1);

        a = from_u128(U64_MAX);
        b = from_u128(2);

        c = as_u128(mul(a, b));

        assert!(c == 36893488147419103230, 2);

        a = from_u128(U128_MAX);
        b = from_u128(U128_MAX);

        let z = mul(a, b);
        assert!(bits(&z) == 256, 3);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_mul_overflow() {
        // let max = (U64_MAX as u64);

        let a = from_u64(1);

        let _ = mul(a, from_u128(U128_MAX));
    }

    #[test]
    fun test_zero() {
        let a = as_u128(zero());
        assert!(a == 0, 0);

        // let a = zero();
        // assert!(a.v0 == 0, 1);
        // assert!(a.v1 == 0, 2);
        // assert!(a.v2 == 0, 3);
        // assert!(a.v3 == 0, 4);
    }

    #[test]
    fun test_from_u64() {
        let a = as_u128(from_u64(100));
        assert!(a == 100, 0);

        // TODO: more tests.
    }

    #[test]
    fun test_compare() {
        let mut a = from_u128(1000);
        let mut b = from_u128(50);

        let mut cmp = compare(&a, &b);
        assert!(cmp == 2, 0);

        a = from_u128(100);
        b = from_u128(100);
        cmp = compare(&a, &b);

        assert!(cmp == 0, 1);

        a = from_u128(50);
        b = from_u128(75);

        cmp = compare(&a, &b);
        assert!(cmp == 1, 2);
    }

    #[test]
    fun test_leading_zeros_u64() {
        let a = leading_zeros_u64(0);
        assert!(a == 64, 0);

        let a = leading_zeros_u64(1);
        assert!(a == 63, 1);

        // TODO: more tests.
    }

    #[test]
    fun test_bits() {
        let mut a = bits(&from_u128(0));
        assert!(a == 0, 0);

        a = bits(&from_u128(255));
        assert!(a == 8, 1);

        a = bits(&from_u128(256));
        assert!(a == 9, 2);

        a = bits(&from_u128(300));
        assert!(a == 9, 3);

        a = bits(&from_u128(60000));
        assert!(a == 16, 4);

        a = bits(&from_u128(70000));
        assert!(a == 17, 5);

        let b = from_u64(70000);
        let sh = shl(b, 100);
        assert!(bits(&sh) == 117, 6);

        let sh = shl(sh, 100);
        assert!(bits(&sh) == 217, 7);

        let sh = shl(sh, 100);
        assert!(bits(&sh) == 0, 8);
    }

    #[test]
    fun test_shift_left() {
        let a = from_u128(100);
        let b = shl(a, 2);

        assert!(as_u128(b) == 400, 0);

        // TODO: more shift left tests.
    }

    #[test]
    fun test_shift_right() {
        let a = from_u128(100);
        let b = shr(a, 2);

        assert!(as_u128(b) == 25, 0);

        // TODO: more shift right tests.
    }

    #[test]
    fun test_div() {
        let a = from_u128(100);
        let b = from_u128(5);
        let d = div(a, b);

        assert!(as_u128(d) == 20, 0);

        let a = from_u128(U64_MAX);
        let b = from_u128(U128_MAX);
        let d = div(a, b);
        assert!(as_u128(d) == 0, 1);

        let a = from_u128(U64_MAX);
        let b = from_u128(U128_MAX);
        let d = div(a, b);
        assert!(as_u128(d) == 0, 2);

        let a = from_u128(U128_MAX);
        let b = from_u128(U64_MAX);
        let d = div(a, b);
        assert!(as_u128(d) == 18446744073709551617, 2);
    }

    #[test]
    #[expected_failure(abort_code=3)]
    fun test_div_by_zero() {
        let a = from_u128(1);
        let _z = div(a, from_u128(0));
    }

    #[test]
    fun test_as_u64() {
        let _ = as_u64(from_u64((U64_MAX as u64)));
        let _ = as_u64(from_u128(1));
    }

    #[test]
    #[expected_failure(abort_code=0)]
    fun test_as_u64_overflow() {
        let _ = as_u64(from_u128(U128_MAX));
    }
}
