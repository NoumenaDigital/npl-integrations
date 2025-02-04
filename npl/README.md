# NPL

The NPL folder is the core of the project and includes code written in NPL — the Noumena Protocol Language.
It defines the data model and the business logic of the application.

## Maven goals

Maven goals are different actions performed on the NPL codebase. The following Maven goals are used in the repository:
- npl-compile: Compiles the NPL code and ensures that it is valid.
- npl-test-compile: Compiles the NPL test code and ensures that it is valid.
- npl-test: Runs the NPL tests.
- npl-api: Generates the OpenAPI specification for the NPL protocols.
- npl-puml: Generates PlantUML diagrams from the NPL data schema.
- npl-multigen: Generates the NPL code used by other node to interact through multi-node.

