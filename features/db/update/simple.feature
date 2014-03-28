@DB
Feature: Update of simple objects
    Testing simple stuff

    Scenario: Remove name from a landuse object
        Given the place nodes
          | osm_id | class   | type  | name
          | 1      | landuse | wood  | 'name' : 'Foo'
        When importing
        Then table placex contains
          | object | class  | type    | name
          | N1     | landuse| wood    | 'name' : 'Foo'
        When updating place nodes
          | osm_id | class   | type 
          | 1      | landuse | wood
        Then table placex has no entry for N1
          

