#!/usr/bin/env bats

setup() {
    echo "content" > test_file.txt
    echo "backup1" > test_file.txt.1
    echo "backup2" > test_file.txt.2
    echo "backup5" > test_file.txt.5
    echo "data" > test_file.txt.7
    gzip -k test_file.txt.7
    echo "backup3" > test_file.txt.3
    gzip test_file.txt.3
    echo "backup9" > test_file.txt.9
    gzip test_file.txt.9
}

teardown() {
    rm -f test_file.txt test_file.txt.[1-9] test_file.txt.[1-9].gz
}

@test "delete removes all uncompressed backups" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ ! -f test_file.txt.1 ]
    [ ! -f test_file.txt.2 ]
    [ ! -f test_file.txt.5 ]
}

@test "delete removes all compressed backups" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ ! -f test_file.txt.3.gz ]
    [ ! -f test_file.txt.7.gz ]
    [ ! -f test_file.txt.9.gz ]
}

@test "delete removes both compressed and uncompressed" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ ! -f test_file.txt.1 ]
    [ ! -f test_file.txt.7.gz ]
}

@test "delete does not remove original file" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt ]
}

@test "delete with no backups exits successfully" {
    rm -f test_file.txt.[1-9] test_file.txt.[1-9].gz
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
}

@test "delete produces no output on success" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "delete is idempotent" {
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    run ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
}

@test "delete ignores backups with numbers greater than 9" {
    echo "backup10" > test_file.txt.10
    echo "backup15" > test_file.txt.15
    ../rotate -d test_file.txt
    [ -f test_file.txt.10 ]
    [ -f test_file.txt.15 ]
    rm -f test_file.txt.10 test_file.txt.15
}