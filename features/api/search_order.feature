Feature: Result order for Geocoding
    Testing that importance ordering returns sensible results

    Scenario Outline: city order in street search
        When sending json search query "<street>, <city>" with address
        Then address of result 0 contains
         | type   | value
         | <type> | <city>

    Examples:
        | type   | city            | street
        | city   | Zürich          | Rigistr
        | city   | Karlsruhe       | Sophienstr
        | county | München         | Karlstr
        | city   | Praha           | Dlouhá

    Scenario Outline: use more important city in street search
        When sending json search query "<street>, <city>" with address
        Then result addresses contain
          | ID | country_code
          | 0  | <country>

    Examples:
        | country | city       | street
        | gb      | London     | Main St
        | gb      | Manchester | Central Street
