#!/usr/bin/env bats

setup() {
    echo "original content" > test_file.txt
}

teardown() {
    rm -f test_file.txt test_file.txt.[1-9] test_file.txt.[1-9].gz
}

@test "backup creates .1 file" {
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
}

@test "backup preserves original file" {
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt ]
    grep -q "original content" test_file.txt
}

@test "backup with -z creates compressed .1.gz" {
    run ../rotate -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
    [ ! -f test_file.txt.1 ]
}

@test "second backup rotates .1 to .2" {
    ../rotate test_file.txt
    echo "second content" > test_file.txt
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2 ]
}

@test "backup respects max count of 3" {
    ../rotate -b 3 test_file.txt
    echo "v2" > test_file.txt
    ../rotate -b 3 test_file.txt
    echo "v3" > test_file.txt
    ../rotate -b 3 test_file.txt
    echo "v4" > test_file.txt
    run ../rotate -b 3 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2 ]
    [ -f test_file.txt.3 ]
    [ ! -f test_file.txt.4 ]
}

@test "backup with n=1 only keeps newest" {
    ../rotate -b 1 test_file.txt
    echo "v2" > test_file.txt
    run ../rotate -b 1 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ ! -f test_file.txt.2 ]
}

@test "backup with n=9 allows maximum backups" {
    for i in $(seq 1 10); do
        echo "version $i" > test_file.txt
        ../rotate -b 9 test_file.txt
    done
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.9 ]
    [ ! -f test_file.txt.10 ]
}

@test "mixed compressed and uncompressed rotation" {
    ../rotate -b 5 test_file.txt
    echo "v2" > test_file.txt
    ../rotate -b 5 -z test_file.txt
    echo "v3" > test_file.txt
    run ../rotate -b 5 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2.gz ]
    [ -f test_file.txt.3 ]
}

@test "no duplicate backups .1 and .1.gz" {
    ../rotate -z test_file.txt
    echo "v2" > test_file.txt
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2.gz ]
    [ ! -f test_file.txt.1.gz ]
}

@test "no duplicate backups at any position" {
    ../rotate -b 3 test_file.txt
    echo "v2" > test_file.txt
    ../rotate -b 3 -z test_file.txt
    echo "v3" > test_file.txt
    ../rotate -b 3 test_file.txt
    echo "v4" > test_file.txt
    run ../rotate -b 3 -z test_file.txt
    [ "$status" -eq 0 ]
    
    for i in 1 2 3; do
        if [ -f "test_file.txt.$i" ] && [ -f "test_file.txt.$i.gz" ]; then
            false
        fi
    done
}

@test "compressed backup preserves .gz during rotation" {
    ../rotate -z test_file.txt
    echo "v2" > test_file.txt
    ../rotate -z test_file.txt
    echo "v3" > test_file.txt
    run ../rotate -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
    [ -f test_file.txt.2.gz ]
    [ -f test_file.txt.3.gz ]
}

@test "uncompressed backup stays uncompressed during rotation" {
    ../rotate test_file.txt
    echo "v2" > test_file.txt
    ../rotate test_file.txt
    echo "v3" > test_file.txt
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2 ]
    [ -f test_file.txt.3 ]
    [ ! -f test_file.txt.1.gz ]
    [ ! -f test_file.txt.2.gz ]
}

@test "backup without -b flag defaults to 5" {
    for i in $(seq 1 6); do
        echo "version $i" > test_file.txt
        ../rotate test_file.txt
    done
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.5 ]
    [ ! -f test_file.txt.6 ]
}

@test "backup 0 is rejected" {
    run ../rotate -b 0 test_file.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a number between 1 and 9" ]]
}

@test "backup 10 is rejected" {
    run ../rotate -b 10 test_file.txt
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a number between 1 and 9" ]]
}

@test "backup with negative number is rejected" {
    run ../rotate -b -5 test_file.txt
    [ "$status" -eq 1 ]
}

@test "backup produces no output on success" {
    run ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "backup can be called multiple times idempotently" {
    ../rotate -b 3 test_file.txt
    ../rotate -b 3 test_file.txt
    run ../rotate -b 3 test_file.txt
    [ "$status" -eq 0 ]
}

@test "backup with -z and -b in any order works" {
    run ../rotate -z -b 3 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
}

@test "switching between compressed and uncompressed works" {
    ../rotate -b 3 -z test_file.txt
    echo "v2" > test_file.txt
    ../rotate -b 3 test_file.txt
    echo "v3" > test_file.txt
    ../rotate -b 3 -z test_file.txt
    echo "v4" > test_file.txt
    run ../rotate -b 3 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
    [ -f test_file.txt.2.gz ]
    [ -f test_file.txt.3 ]
}

@test "backup preserves modification timestamp" {
    ORIG_TIME=$(stat -c %Y test_file.txt 2>/dev/null || stat -f %m test_file.txt)
    sleep 1
    ../rotate test_file.txt
    BACKUP_TIME=$(stat -c %Y test_file.txt.1 2>/dev/null || stat -f %m test_file.txt.1)
    [ "$ORIG_TIME" -eq "$BACKUP_TIME" ]
}

@test "compressed backup preserves modification timestamp" {
    ORIG_TIME=$(stat -c %Y test_file.txt 2>/dev/null || stat -f %m test_file.txt)
    sleep 1
    ../rotate -z test_file.txt
    BACKUP_TIME=$(stat -c %Y test_file.txt.1.gz 2>/dev/null || stat -f %m test_file.txt.1.gz)
    [ "$ORIG_TIME" -eq "$BACKUP_TIME" ]
}

@test "rotation preserves timestamps of existing backups" {
    ORIG_TIME=$(stat -c %Y test_file.txt 2>/dev/null || stat -f %m test_file.txt)
    ../rotate test_file.txt
    sleep 1
    echo "v2" > test_file.txt
    ../rotate test_file.txt
    BACKUP2_TIME=$(stat -c %Y test_file.txt.2 2>/dev/null || stat -f %m test_file.txt.2)
    [ "$ORIG_TIME" -eq "$BACKUP2_TIME" ]
}

@test "backup preserves file permissions" {
    chmod 640 test_file.txt
    ../rotate test_file.txt
    ORIG_PERMS=$(stat -c %a test_file.txt 2>/dev/null || stat -f %Op test_file.txt | cut -c 4-6)
    BACKUP_PERMS=$(stat -c %a test_file.txt.1 2>/dev/null || stat -f %Op test_file.txt.1 | cut -c 4-6)
    [ "$ORIG_PERMS" = "$BACKUP_PERMS" ]
}

@test "compressed backup preserves file permissions" {
    chmod 600 test_file.txt
    ../rotate -z test_file.txt
    ORIG_PERMS=$(stat -c %a test_file.txt 2>/dev/null || stat -f %Op test_file.txt | cut -c 4-6)
    BACKUP_PERMS=$(stat -c %a test_file.txt.1.gz 2>/dev/null || stat -f %Op test_file.txt.1.gz | cut -c 4-6)
    [ "$ORIG_PERMS" = "$BACKUP_PERMS" ]
}