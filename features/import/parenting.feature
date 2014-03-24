@DB
Feature: Parenting of objects
    Tests that the correct parent is choosen


    Scenario: Address without addr tags
        Given the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | 0.0001,0.00001
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | 0 0, 1 0
        When importing
        Then parent of N1 is W1


    Scenario: Address without tags, closest street
        Given the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | 0.0001,0.0001
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | 0 0, 1 0
         | 2      | highway | residential | 'name' : 'foobar' | 0 0.00005, 1 0.00005
        When importing
        Then parent of N1 is W2

