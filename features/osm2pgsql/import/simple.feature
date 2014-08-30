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
          | 200 | 0 0
          | 201 | 0 1
          | 202 | 1 1
          | 203 | 1 0
        Given the osm ways:
          | id | tags                             | nodes
          | 1  | 'shop' : 'toys', 'name' : 'tata' | 100 101 102
          | 2  | 'ref' : '45'                     | 200 201 202 203 200
        Given the osm relations:
          | id | tags                                                        | members
          | 1  | 'type' : 'multipolygon', 'tourism' : 'hotel', 'name' : 'XZ' | N1,W2
        When loading osm data
        Then table place contains
          | object | class   | type   | name
          | N1     | amenity | prison | 'name' : 'foo'
          | W1     | shop    | toys   | 'name' : 'tata'
          | R1     | tourism | hotel  | 'name' : 'XZ'

