@DB
Feature: Parenting of objects
    Tests that the correct parent is choosen


    Scenario: Address without addr tags
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :p-N1
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | :w-north
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1


    Scenario: Address without tags, closest street
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :p-N1
         | 2      | place | house | :p-N2
         | 3      | place | house | :p-S1
         | 4      | place | house | :p-S2
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | :w-north
         | 2      | highway | residential | 'name' : 'foobar' | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W2
         | N4     | W2

