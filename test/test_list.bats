#!/usr/bin/env bats

setup() {
    echo "content" > test_file.txt
    echo "backup1" > test_file.txt.1
    echo "backup3" > test_file.txt.3
    echo "backup5" > test_file.txt.5
    echo "some data" > test_file.txt.2
    gzip -k test_file.txt.2
    echo "backup9" > test_file.txt.9
    gzip test_file.txt.9
}

teardown() {
    rm -f test_file.txt test_file.txt.[1-9] test_file.txt.[1-9].gz
}

@test "list shows existing uncompressed backups" {
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_file.txt.1" ]]
    [[ "$output" =~ "test_file.txt.3" ]]
    [[ "$output" =~ "test_file.txt.5" ]]
}

@test "list shows compressed backups" {
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_file.txt.2.gz" ]]
    [[ "$output" =~ "test_file.txt.9.gz" ]]
}

@test "list shows both compressed and uncompressed" {
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_file.txt.1" ]]
    [[ "$output" =~ "test_file.txt.2.gz" ]]
}

@test "list with no backups shows only original file" {
    rm -f test_file.txt.[1-9] test_file.txt.[1-9].gz
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_file.txt" ]]
    ! [[ "$output" =~ "test_file.txt.1" ]]
}

@test "list output format matches ls -l" {
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^-.* ]]
}

@test "list ignores backups with numbers greater than 9" {
    echo "backup10" > test_file.txt.10
    echo "backup15" > test_file.txt.15
    run ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    ! [[ "$output" =~ "test_file.txt.10" ]]
    ! [[ "$output" =~ "test_file.txt.15" ]]
    rm -f test_file.txt.10 test_file.txt.15
}