@DB
Feature: Import of simple objects by osm2pgsql
    Testing basic functions of osm2pgsql.

    Scenario: Import a node
        Given the osm nodes:
          | id | tags
          | 1  | 'amenity' : 'prison', 'name' : 'foo'
        When loading osm data
        Then table place contains
          | object | class   | type   | name
          | N1     | amenity | prison | 'name' : 'foo'
