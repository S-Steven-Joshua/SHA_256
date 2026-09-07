import hashlib


# ============================================================
# Configuration
# ============================================================

RESULT_FILE = r"D:\protocol\sha_256\sha256_results.txt"

MAX_LENGTH = 31


# ============================================================
# Counters
# ============================================================

total = 0
passed = 0
failed = 0

failures = []


# ============================================================
# Read RTL results
#
# File format:
#
# TEST_ID LENGTH DATA_IN RTL_HASH
#
# Example:
#
# 0 13 6b7920746b726c6a6a706774610000... b735e360...
# ============================================================

with open(RESULT_FILE, "r") as f:

    for line in f:

        line = line.strip()


        # ----------------------------------------------------
        # Skip empty lines and comments
        # ----------------------------------------------------

        if not line or line.startswith("#"):
            continue


        fields = line.split()


        # ----------------------------------------------------
        # Check file format
        # ----------------------------------------------------

        if len(fields) != 4:

            print("ERROR: Invalid result line:")
            print(line)
            continue


        # ----------------------------------------------------
        # Extract fields
        # ----------------------------------------------------

        test_id = int(fields[0])
        length  = int(fields[1])

        data_hex = fields[2].lower()
        rtl_hash = fields[3].lower()


        # ----------------------------------------------------
        # Basic checks
        # ----------------------------------------------------

        if length < 0 or length > MAX_LENGTH:

            print(
                f"ERROR: Test {test_id}: "
                f"invalid length = {length}"
            )

            failed += 1
            total += 1

            continue


        if len(data_hex) != 64:

            print(
                f"ERROR: Test {test_id}: "
                f"DATA_IN is not 256 bits"
            )

            failed += 1
            total += 1

            continue


        if len(rtl_hash) != 64:

            print(
                f"ERROR: Test {test_id}: "
                f"RTL hash is not 256 bits"
            )

            failed += 1
            total += 1

            continue


        # ----------------------------------------------------
        # Convert 256-bit DATA_IN into bytes
        # ----------------------------------------------------

        try:

            data = bytes.fromhex(data_hex)

        except ValueError:

            print(
                f"ERROR: Test {test_id}: "
                f"invalid hexadecimal DATA_IN"
            )

            failed += 1
            total += 1

            continue


        # ----------------------------------------------------
        # Extract only the actual message bytes
        #
        # DATA_IN layout:
        #
        # [255:248] = character 0
        # [247:240] = character 1
        # ...
        #
        # Therefore bytes(data[:length]) gives the
        # original message.
        # ----------------------------------------------------

        message = data[:length]


        # ----------------------------------------------------
        # Calculate golden SHA-256
        # ----------------------------------------------------

        expected_hash = hashlib.sha256(
            message
        ).hexdigest()


        # ----------------------------------------------------
        # Compare
        # ----------------------------------------------------

        total += 1


        if rtl_hash == expected_hash:

            passed += 1


        else:

            failed += 1

            failures.append(
                {
                    "test_id": test_id,
                    "length": length,
                    "data_hex": data_hex,
                    "message": message,
                    "expected": expected_hash,
                    "rtl": rtl_hash
                }
            )


# ============================================================
# Print regression summary
# ============================================================

print()
print("==================================================")
print("             SHA-256 REGRESSION")
print("==================================================")
print()

print(f"Total tests : {total}")
print(f"Passed      : {passed}")
print(f"Failed      : {failed}")

print()
print("==================================================")


# ============================================================
# Print failures
# ============================================================

if failed > 0:

    print()
    print("FAILURES")
    print("--------------------------------------------------")


    # Show first 20 failures only
    for failure in failures[:20]:

        print()
        print(f"Test ID : {failure['test_id']}")
        print(f"Length  : {failure['length']}")

        print(
            f"Message : {failure['message']!r}"
        )

        print(
            f"DATA    : {failure['data_hex']}"
        )

        print(
            f"Expected: {failure['expected']}"
        )

        print(
            f"RTL     : {failure['rtl']}"
        )


    if failed > 20:

        print()
        print(
            f"... {failed - 20} more failures "
            f"not displayed"
        )


# ============================================================
# Final result
# ============================================================

print()
print("==================================================")

if failed == 0:

    print("RESULT : ALL TESTS PASSED")

else:

    print("RESULT : REGRESSION FAILED")

print("==================================================")
print()


# ============================================================
# Return error code for automation/CI
# ============================================================

if failed != 0:

    raise SystemExit(1)
