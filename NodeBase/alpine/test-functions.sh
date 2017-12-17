#!/usr/bin/env bats

source "$BATS_TEST_DIRNAME"/functions.sh

# Tests for function get_server_num
#
# Test data from http://askubuntu.com/questions/432255/what-is-display-environment-variable
@test 'get_server_num of :99.1' {

  export DISPLAY=':99.1'
  expected_result='99'
  result="$(get_server_num)"
  echo "result: $result"
  [ "$result" == "$expected_result" ]
}

@test 'get_server_num of :0' {

  export DISPLAY=':0'
  expected_result='0'
  result="$(get_server_num)"
  echo "result: $result"
  [ "$result" == "$expected_result" ]
}

@test 'get_server_num of localhost:4' {

  export DISPLAY='localhost:4'
  expected_result='4'
  result="$(get_server_num)"
  echo "result: $result"
  [ "$result" == "$expected_result" ]
}

@test 'get_server_num of google.com:0' {

  export DISPLAY='google.com:0'
  expected_result='0'
  result="$(get_server_num)"
  echo "result: $result"
  [ "$result" == "$expected_result" ]
}

@test 'get_server_num of google.com:99.1' {

  export DISPLAY='google.com:99.1'
  expected_result='99'
  result="$(get_server_num)"
  echo "result: $result"
  [ "$result" == "$expected_result" ]
}

