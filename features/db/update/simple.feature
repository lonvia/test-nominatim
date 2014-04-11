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
          
          
    Scenario: Do delete small boundary features
        Given the place areas
          | osm_type | osm_id | class    | type           | admin_level | geometry
          | R        | 1      | boundary | administrative | 3           | (0 0, 1 0, 1 1, 0 1, 0 0)
        When importing
        Then table placex contains
          | object | rank_search
          | R1     | 6
        When marking for delete R1
        Then table placex has no entry for R1

    Scenario: Do not delete large boundary features
        Given the place areas
          | osm_type | osm_id | class    | type           | admin_level | geometry
          | R        | 1      | boundary | administrative | 3           | (0 0, 2 0, 2 2.1, 0 2, 0 0)
        When importing
        Then table placex contains
          | object | rank_search
          | R1     | 6
        When marking for delete R1
        Then table placex contains 
          | object | rank_search
          | R1     | 6

    Scenario: Do delete large features of low rank
        Given the named place areas
          | osm_type | osm_id | class    | type          | geometry
          | W        | 1      | place    | house         | (0 0, 2 0, 2 2.1, 0 2, 0 0)
          | R        | 1      | boundary | national_park | (0 0, 2 0, 2 2.1, 0 2, 0 0)
        When importing
        Then table placex contains
          | object | rank_address
          | R1     | 0
          | W1     | 30
        When marking for delete R1,W1
        Then table placex has no entry for W1
        Then table placex has no entry for R1
