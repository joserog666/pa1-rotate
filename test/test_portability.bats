#!/usr/bin/env bats

setup() {
    echo "test content" > test_file.txt
}

teardown() {
    rm -f test_file.txt test_file.txt.[1-9] test_file.txt.[1-9].gz
}

@test "dash: basic backup works" {
    run dash ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
}

@test "bash: basic backup works" {
    run bash ../rotate test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
}

@test "dash: backup with -b flag works" {
    run dash ../rotate -b 3 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
}

@test "bash: backup with -b flag works" {
    run bash ../rotate -b 3 test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1 ]
}

@test "dash: compression works" {
    run dash ../rotate -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
}

@test "bash: compression works" {
    run bash ../rotate -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
}

@test "dash: compression with -b works" {
    run dash ../rotate -b 3 -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
}

@test "bash: compression with -b works" {
    run bash ../rotate -b 3 -z test_file.txt
    [ "$status" -eq 0 ]
    [ -f test_file.txt.1.gz ]
}

@test "dash: delete works" {
    echo "backup1" > test_file.txt.1
    echo "backup2" > test_file.txt.2
    run dash ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ ! -f test_file.txt.1 ]
}

@test "bash: delete works" {
    echo "backup1" > test_file.txt.1
    echo "backup2" > test_file.txt.2
    run bash ../rotate -d test_file.txt
    [ "$status" -eq 0 ]
    [ ! -f test_file.txt.1 ]
}

@test "dash: list works" {
    echo "backup1" > test_file.txt.1
    run dash ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_file.txt ]]
}

@test "bash: list works" {
    echo "backup1" > test_file.txt.1
    run bash ../rotate -l test_file.txt
    [ "$status" -eq 0 ]
    [[ "$output" =~ test_file.txt ]]
}