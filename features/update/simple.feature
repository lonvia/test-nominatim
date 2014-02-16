@DB
Feature: Update of simple objects
    Testing simple stuff

    Scenario: Remove name from a landuse object
        Given the place nodes
          | osm_id | class   | type  | name
          | 1      | landuse | wood  | 'name' : 'Foo'
        When importing
        Then placex contains for N1
          | class  | type    | name
          | landuse| wood    | 'name' : 'Foo'
        When updating the place nodes
          | osm_id | class   | type 
          | 1      | landuse | wood
        Then placex has no entry for N1
          

