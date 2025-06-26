# closer to final #
Dev-Unstable2 --> Dev-Unstable -->  Dev-Stable -->  Test-Qc  -->  Staging   --> Prod

Comments:
The development work progresses from DevStable to the right.   You've this month requested DevUnstable and DevUnstable2 so where those are to be used, they are to the left... and again, things move right.
Sometimes you go backwards from right to left, for example if something fails in DevTest-QC, it is rejected and even deleted, and Staging and Prod are untouched.
Sometimes code on the left never moves forward to the right.  e.g. Didn't work.  Too slow, another approach/algorithm will be tried.

If there is an OS patch to apply urgently, IT will apply in Staging, ask you guys to test, and then apply to Prod.
If there is something weird going on in Prod, and you want to do a non-destructive test.  Or you can't reproduce in DevTest-QC something that is going on in Prod, then you can try on Staging.  This is especially important for tests or problems that may slow things down for users in Prod.   Often you cannot do this on DevTest-qc because it may have a newer release of the code being tested and repeatedly modified on it.
If Prod suffers catastrophic hardware failure,  Staging will be modified to become Prod.  So in a sense, in this case is the emergency spare Prod machine.  (There were some limitations with regard to a lack of funds for purchasing hardware, but this should be the goal and should be resolved in the future.  In the beginning we doubled-uped on some machines and used vms because you said that development would not be that extensive.  Even the vendor said they normally just have test and prod for their customers.   


# Currently discussed (2019) #

| instance type | planned instance role | current server name | current server use                                         |
|---------------|-----------------------|---------------------|------------------------------------------------------------|
| prod          | prod                  | prod                | prod                                                       |
| qc            | qc                    | staging             | used by IT to test installations                           |
| dev           | dev-stable            | dev                 | mirror of prod to initially develop triton                 |
| dev           | dev-unstable1         | test                | main dev environment, lab training                         |
| dev           | dev-unstable2         | portal              | mirror of prod for official triton, only need the database |


# Initial Plan (2017-) #

Tier  - Description

* Dev
Mazur, Haig and whichever other developer comes on board in the future to backup Mazur. The developers have carte blanche to do make changes without affecting anyone or being too concerned about impact.  This is the most dynamic and potentially unstable tier.  Changes by Developers.

* Test
Stuff that developers or IT promote for Quality Assurance Testing by Beta Testers (Key Users).  Updates and patches may need to be rolled back.  The system may need to be restored due to it being messed up.  Changes made by Developers or IT.

* Staging
Mainly for use by IT for pre-testing installation of updates, Operating System or hardware driver updates  before they are promoted to production.   Also, if there are issues in production, instead of experimenting on the Production system, attempts may be made to reproduce the issue in Staging before coming up with a solution.  Once the solution is found, it is tested in Staging, before it is put into production.   The Staging system should not need to be restored frequently.   It should be kept as stable as possible along with Production.   Controlled, co-ordinatated changes by IT.

* Production
The live system.  No experimenting here.   Controlled, co-ordinatated changes by IT.

We installed test and prod with Clarity initially. dev and portal were deployed later by IT using our own procedures.

