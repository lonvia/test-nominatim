@DB
Feature: Import of simple objects
    Testing simple stuff

    Scenario: Import place node
        Given the place nodes:
          | osm_id | class | type    | name
          | 1      | place | village | 'name' : 'Foo'
        When importing
        Then table placex contains
          | object | class  | type    | name
          | N1     | place  | village | 'name' : 'Foo'
        When sending query "Foo"
        Then results contain
         | ID | osm_type | osm_id
         | 0  | N        | 1

