 # Clarity Role-Based Permissions #

 



2019_11_05,	Alexander Mazur, McGill University

 

 ## PROD server: Role-Based Permissions ##

| N  | Base permission          | Collaborator | Researcher | Facility Administrator | System Administrator |
|----|--------------------------|--------------|------------|------------------------|----------------------|
| 1  | APILogin                 |              |            | X                      | X                    |
| 2  | ClarityLogin             |              | X          | X                      | X                    |
| 3  | CollaborationsLogin      | X            | X          | X                      | X                    |
| 4  | Configuration:update     |              |            |                        | X                    |
| 5  | Contact:create           |              |            | X                      | X                    |
| 6  | Contact:delete           |              |            | X                      | X                    |
| 7  | Contact:read             |              |            | X                      | X                    |
| 8  | Contact:update           |              |            | X                      | X                    |
| 9  | Controls:create          |              |            | X                      | X                    |
| 10 | Controls:delete          |              |            | X                      | X                    |
| 11 | Controls:update          |              |            | X                      | X                    |
| 12 | MoveToNextStep           |              |            | X                      | X                    |
| 13 | OperationsLogin          |              |            | X                      | X                    |
| 14 | OverviewDashboard:read   |              |            | X                      | X                    |
| 15 | Process:create           |              |            | X                      | X                    |
| 16 | Process:read             |              |            | X                      | X                    |
| 17 | Process:update           |              |            | X                      | X                    |
| 18 | Project:create           | X            | X          | X                      | X                    |
| 19 | Project:delete           | X            | X          | X                      | X                    |
| 20 | ReQueueSample            |              | X          | X                      | X                    |
| 21 | ReagentKit:create        |              |            | X                      | X                    |
| 22 | ReagentKit:delete        |              |            | X                      | X                    |
| 23 | ReagentKit:update        |              |            | X                      | X                    |
| 24 | RemoveSampleFromWorkflow |              |            | X                      | X                    |
| 25 | ReviewEscalatedSamples   |              |            | X                      | X                    |
| 26 | Role:create              |              |            | X                      | X                    |
| 27 | Role:delete              |              |            | X                      | X                    |
| 28 | Role:update              |              |            | X                      | X                    |
| 29 | Sample:create            | X            | X          | X                      | X                    |
| 30 | Sample:delete            | X            | X          | X                      | X                    |
| 31 | Sample:update            | X            | X          | X                      | X                    |
| 32 | SampleRework             |              |            | X                      | X                    |
| 33 | SampleWorkflowAssignment |              | X          | X                      | X                    |
| 34 | User:create              |              |            | X                      | X                    |
| 35 | User:delete              |              |            | X                      | X                    |
| 36 | User:read                |              |            | X                      | X                    |
| 37 | User:update              |              |            | X                      | X                    |
| 38 | eSignatureSigning        |              |            | X                      | X                    |
| 39 | SearchIndex              |              |            |                        | X                    |