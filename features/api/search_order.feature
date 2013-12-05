Feature: Result order for Geocoding
    Testing that importance ordering returns sensible results

    Scenario Outline: city order in street search
        When searching for "<street>, <city>"
        Using format json
        Then address 1 contains <type> "<city>"

    Examples:
        | type | city            | street
        | city | Zürich          | Rigistr
        | city | Karlsruhe       | Sophienstr
        | county | München         | Karlstr
        | city | Praha           | Dlouhá

    Scenario Outline: use more important city in street search
        When searching for "<street>, <city>"
        Using format json
        Then address 1 contains country_code "<country>"

    Examples:
        | country | city       | street
        | gb      | London     | Main St
        | gb      | Manchester | Central Street
