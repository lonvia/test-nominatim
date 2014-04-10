@DB
Feature: Parenting of objects
    Tests that the correct parent is choosen


    Scenario: Address without addr tags
        Given the scenario roads-with-pois
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :p-N1
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | :w-north
        When importing
        Then parent of N1 is W1


    Scenario: Address without tags, closest street
        Given the scenario roads-with-pois
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
        Then parent of N1 is W1
        And parent of N2 is W1
        And parent of N3 is W2
        And parent of N4 is W2

