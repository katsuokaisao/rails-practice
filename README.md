# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

## Ruby version
3.3.7

## Configuration

## Database set up

### create database
```bash
bin/rails db:create
```

### apply schema
dry-run

```bash
bundle exec ridgepole -c config/database.yml -E development -f db/schemas/Schemafile --apply --dry-run
bundle exec ridgepole -c config/database.yml -E test -f db/schemas/Schemafile --apply --dry-run
```

apply
```bash
bundle exec ridgepole -c config/database.yml -E development -f db/schemas/Schemafile --apply
bundle exec ridgepole -c config/database.yml -E test -f db/schemas/Schemafile --apply
```

## How to run the test suite

## Services (job queues, cache servers, search engines, etc.)
