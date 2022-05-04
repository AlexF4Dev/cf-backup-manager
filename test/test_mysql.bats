# mysql integration tests

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"

  export DATASTORE_S3_SERVICE_NAME

  # Create the bucket
  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "mysql backup and restore" {
  run backup mysql application-mysql-db /mysql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up application-mysql-db (mysql) to /mysql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore mysql application-mysql-db /mysql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring application-mysql-db (mysql) from /mysql-backup.sql.gz...'
  assert_output --partial 'ok'
}

# TODO: create separate db, the test reuses db
@test "mysql backup and restore with db with db list" {
  run backup mysql application-mysql-db:application-mysql-db /mysql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up application-mysql-db (mysql) to /mysql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore mysql application-mysql-db:application-mysql-db /mysql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring application-mysql-db (mysql) from /mysql-backup.sql.gz...'
  assert_output --partial 'ok'

  run list_databases  mysql application-mysql-db
  
  assert_success
  assert_output --partial 'Database'
  assert_output --partial 'application-mysql-db'
  assert_output --partial 'ok'
}

@test "mysql create and delete database" {
  run create_database mysql "application-mysql-db:test-db"
  assert_success
  assert_output --partial 'ok'
  
  run list_databases  mysql application-mysql-db
  assert_success
  assert_output --partial 'test-db'

  run run_sql  mysql application-mysql-db:test-db 'SHOW DATABASES'
  assert_success
  assert_output --partial 'test-db'

  run run_sql  mysql application-mysql-db:test-db 'CREATE TABLE TEST (col int)'
  assert_success

  run run_sql  mysql application-mysql-db:test-db 'SELECT * FROM TEST'
  assert_success

  run delete_database mysql "application-mysql-db:test-db"
  assert_success
  assert_output --partial 'ok'
}
