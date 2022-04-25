function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}
@test "print given invalid args" {
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run print
  assert_failure
  assert_output --partial "[backup_path]"
}

@test "print file succeeds" {
  # Create a test file 
  echo 'Random sample text' > $BATS_TEST_TMPDIR/test-file
  aws_helper s3 cp $BATS_TEST_TMPDIR/test-file s3://$TEST_DATASTORE_BUCKET/test-file
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run print test-file
  assert_success
  assert_output --partial "Random sample text"
}
