@DB
Feature: Import of simple objects
    Testing simple stuff

    Scenario: Import place node
        Given the place nodes:
          | osm_id | class | type    | name
          | 1      | place | village | 'name' : 'Foo'
        When importing
        Then placex contains for N1
          | class  | type    | name
          | place  | village | 'name' : 'Foo'
          

