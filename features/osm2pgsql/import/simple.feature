@DB
Feature: Import of simple objects by osm2pgsql
    Testing basic functions of osm2pgsql.

    Scenario: Import simple objects
        Given the osm nodes:
          | id | tags
          | 1  | 'amenity' : 'prison', 'name' : 'foo'
        Given the osm nodes:
          | id  | geometry
          | 100 | 0 0
          | 101 | 0 0.1
          | 102 | 0.1 0.2
        Given the osm ways:
          | id | tags                             | nodes
          | 1  | 'shop' : 'toys', 'name' : 'tata' | 100 101 102
        When loading osm data
        Then table place contains
          | object | class   | type   | name
          | N1     | amenity | prison | 'name' : 'foo'
          | W1     | shop    | toys   | 'name' : 'tata'

