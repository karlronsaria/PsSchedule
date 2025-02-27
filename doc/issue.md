# issue

- [x] 2025-02-17-014805
  - log

    ```text
    C:\note  master  ?3 ~7  $what = get-mySchedule -Subdirectory employer -Pattern 'day camp' -Mode Link
    C:\note  master  ?3 ~7  $what
    C:\note\sched\notebook\employer\sched_-_2023-11-07_CodeNinjasEvent.md
    C:\note  master  ?3 ~7  $what | foreach { Split-Path -Path $_ -Parent }
    C:\note\sched\notebook\employer
    Split-Path: Cannot bind argument to parameter 'Path' because it is null.
    C:\note  master  ?3 ~7  $what.Count
    2
    C:\note  master  ?3 ~7  $what[-1]
    C:\note  master  ?3 ~7 
    ```

- [ ] 2024-10-13-150719

  - howto

    ```powershell
    Find-MyTree -Subdirectory request -Tag Partners
    ```

  - actual
    - five duplicates of the expected output

- [ ] 2024-10-10-213557

  - actual

    ```text
    Sunday (2024-10-27)
    -------------------
    00:00  [ ] ⟐ todo: event: Code Ninjas: Birthday Party
    15:00  [ ] ---
    ```

- [ ] 2024-10-02-002616

  - note
    - possible reason
      - ``event`` is marked as an exclusive item type
      - ``event`` probably doesn't have any code that processes it as part of a list
  - howto
    - in markdown

      ```markdown
      # sched: move: ...

      - when: 2024-10-02-1330
      - to: 1550
      - type: event, overlap, move
      ```

    - in powershell

      ```powershell

      Get-MySchedule -Subdirectory employer
      ```

  - actual

    ```text
    Wednesday (2024-10-02)
    ----------------------
    00:00      ⟐ overlap: event: move: ...
    ```

  - expected

    ```text
    Wednesday (2024-10-02)
    ----------------------
    13:30      ⟐ overlap: event: move: ...
    ```

- [ ] 2024-10-02-002001

  - howto

    ```powershell
    (Get-MySchedule -Subdirectory employer -Pattern meet -Mode Link).Count
    ```

  - actual: ``2``
    - one item is null or an empty string
  - expected: ``1``

- [ ] 2024-10-02-001708

  - howto

    ```powershell
    Get-MySchedule -Subdirectory employer -Pattern sassafrass
    ```

  - actual

    ```text
    No content in C:\note\sched\notebook\employer could be found matching the pattern 'sassafrass'
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\__COMPLETE'. Please use 'Get-ChildItem' instead.
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\__POOL'. Please use 'Get-ChildItem' instead.
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\banter'. Please use 'Get-ChildItem' instead.
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\budget'. Please use 'Get-ChildItem' instead.
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\contact'. Please use 'Get-ChildItem' instead.
    Get-Content:
    Line |
     566 |                  Get-Content |
         |                  ~~~~~~~~~~~
         | Unable to get content because it is a directory: 'C:\note\dev'. Please use 'Get-ChildItem' instead.
    ```

- [ ] 2024-10-02-000827

  - consider
    - this is by design

  - howto
    - in markdown

      ```markdown
      # sched:
      ```

    - in powershell

      ```powershell
      Get-MySchedule -Subdirectory employer -Pattern campus
      ```

  - actual

    ```text
    InvalidArgument: C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\MarkdownTree\script\Object.ps1:703
    Line |
     703 |                                          $stack[$level]
         |                                          ~~~~~~~~~~~~~~
         | Cannot convert value "System.Collections.Specialized.OrderedDictionary" to type
         | "System.Management.Automation.LanguagePrimitives+InternalPSCustomObject". Error:
         | "Cannot process argument because the value of argument "name" is not valid. Change
         | the value of the "name" argument and run the operation again."
    ```

    - other
      - howto
        - in markdown

          ```markdown
          # sched
          ```

      - actual

        ```text
        Wednesday (2024-10-02)
        ----------------------
        00:10      ⟐ Length
        00:10      ⟐ LongLength
        00:10      ⟐ Rank
        00:10      ⟐ SyncRoot
        00:10      ⟐ IsReadOnly
        00:10      ⟐ IsFixedSize
        00:10      ⟐ IsSynchronized
        00:10      ⟐ Count
        ```

- [ ] 2024-09-26-043319

  - howto

    ```powershell
    Get-MySchedule -Subdirectory request -StartDate 2024-09-25
    ```

  - actual

    ```text
    ```

- [ ] 2024-07-07-140732

  - howto
    - in markdown

      ```text
      # sched
      - tag: @counsel @ChangeAndGrowthPlan
      - what: meet with Roi
      - when:
      - type: event
      - note
        - when: 2023-01-26-1030
        - when: 2023-01-12-1030
      ```

  - actual
    - in powershell

      ```text
      C:\note [master ≡]> Get-MySchedule

      Sunday (2024-07-07)
      -------------------
      10:00      ⟐ daily todo
      11:00      ⟐ event: Sunday service
      14:08      ⟐ event: meet with Roi

      Monday (2024-07-08)
      -------------------
      16:00  [!] ⟐ general offering

      Tuesday (2024-07-09)
      --------------------
      18:30      ⟐ event: bible study men's

      Saturday (2024-07-13)
      ---------------------
      13:30      ⟐ event: meet with Jesse Luna
      14:30      ---
      ```

- [ ] 2023-01-10-230005

  - howto
    - in powershell

      ```powershell
      $tree = cat .\todo_-_2022-12-16.md | Get-MarkdownTable
      $tree.lookup | Write-MarkdownTree
      ```
    - in ``todo_-_2022-12-16.md``

      ```
      # lookup
      - howto: tie shoes efficiently
        - [ ] learn
        - [x] find
          - link
            - search
              - How To Tie Your Shoes Insanely Fast!
              - SharpshooterJD
              - YouTube
            - retrieved: 2023-01-10
      - howto: remove windshield glare
        - [ ] learn
        - [x] find
          - link
            - search
              - STOP Auto Glass GLARE & WATER SPOTS....FOREVER!!!!!
              - Sweet Project Cars
              - YouTube
            - retrieved: 2023-01-10
      - [ ] learn: webassembly
        - [ ] link video in listen-later playlist
      - [ ] learn: Hindley-Milner type system
      ```
  - actual

    ```
    - howto
      - tie shoes efficiently
      - remove windshield glare
    - [ ] learn
      - webassembly
      - Hindley-Milner type system
    ```
  - expected

    ```
    - howto
      - tie shoes efficiently
        - [ ] learn
        - [x] find
          - link
            - search
              - How To Tie Your Shoes Insanely Fast!
              - SharpshooterJD
              - YouTube
            - retrieved: 2023-01-10
      - remove windshield glare
        - [ ] learn
        - [x] find
          - link
            - search
              - STOP Auto Glass GLARE & WATER SPOTS....FOREVER!!!!!
              - Sweet Project Cars
              - YouTube
            - retrieved: 2023-01-10
    - learn
      - [ ] webassembly
        - [ ] link video in listen-later playlist
      - [ ] Hindley-Milner type system
    ```

- [ ] 2022-10-27-180542

  - actual
    - action items with header levels other than 3 are ignored

- [ ] 2023-01-20-144131

  - what
    - ``Get-MySchedule``: ``Extension`` parameter is never used due to all work files having the markdown ``*.md`` extension.

- [ ] 2023-02-07-212709
  - howto
    - in powershell
      ```powershell
      Get-MySchedule request, partners, tree
      ```
    - in ``sched.md``
      ```
      # sched
      - who: Code Ninjas Ladera Ranch CA
      - what
        - phone interview
          - where: phone
          - when: 2023-02-04-1300
          - type: event
          - every: none
        - personal interview
          - where
            - address: 25652 Crown Valley Pkwy Suite F-1, Ladera Ranch, CA 92694
          - when: 2023-02-08-1300
          - type: event
          - every: none
      ```
  - actual
    ```
    Tuesday (2023-02-07)
    --------------------
    21:28      @{phone interview=; personal interview=}
    ```

- [ ] 2023-02-06-092921
  - howto
    ```powershell
    Get-MySchedule request, partners, tree
    ```
  - actual
    ```
    Get-MySchedule -Subdirectory 'request' -Mode 'tree' -Extension '*.md' -Pattern 'partners'

    - when
      - 02/06/2023 11:00:00
    - what
      - counsel
    - type
      - todayonly
    - when
      - 02/06/2023 11:00:00
    - what
      - evangelism
    - type
      - todayonly
    - when
      - 02/06/2023 11:00:00
    - what
      - Partners
    - type
      - todayonly
    ```
    - output is an array of strings
  - expected
    - output is a PsCustomObject

- [x] 2023-10-02-020437
  - howto
    - in powershell
      ```powershell
      cat myFile.md | Get-MarkdownTree
      ```
    - in markdown
      ```
      - [ ] sep: hir
      ```
  - actual
    ```
    sep
    ---
    hir
    ```
  - expected
    ```
    complete sep
    -------- ---
    False    hir
    ```

- [x] 2023-08-22-202828
  - actual
    ```
    C:\Users\karlr> Get-MySchedule -Subdirectory general -Mode Edit -Pattern amazon

    C:\note\sched\notebook\general\sched_-_2022-12-18_Delivery.md:8:  - url: https://www.amazon.com
    This will open to editor all files in
      C:\note\sched\notebook\general\sched_-_2022-12-18_Delivery.md:8:  - url: https://www.amazon.com

    Continue? (y/n):
    ```

- [x] 2023-09-11-125704
  - actual
    ```
    C:\Users\karlr> Get-MySchedule general, cat, offering
    The variable '$startDate_subitem' cannot be retrieved because it has not been
    set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script
    \MySchedule.ps1:321 char:22
    +             if (-not $startDate_subitem `
    +                      ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (startDate_subitem:String) [],
       RuntimeException
        + FullyQualifiedErrorId : VariableIsUndefined

    The variable '$startDate_subitem' cannot be retrieved because it has not been
    set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script
    \MySchedule.ps1:321 char:22
    +             if (-not $startDate_subitem `
    +                      ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (startDate_subitem:String) [],
       RuntimeException
        + FullyQualifiedErrorId : VariableIsUndefined

    The variable '$startDate_subitem' cannot be retrieved because it has not been
    set.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script
    \MySchedule.ps1:321 char:22
    +             if (-not $startDate_subitem `
    +                      ~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (startDate_subitem:String) [],
       RuntimeException
        + FullyQualifiedErrorId : VariableIsUndefined

    Get-MySchedule -Subdirectory '' -Mode 'Schedule' -Extension '*.md'


    Monday (2023-09-11)
    -------------------
    00:00  [ ] todo: reappoint: meet with Roi
    10:00      daily todo
    16:00  [!] general offering

    Tuesday (2023-09-12)
    --------------------
    18:30      event: bible study men's

    Saturday (2023-09-16)
    ---------------------
    13:30      event: meet with Jesse Luna
    14:30      ---

    Sunday (2023-09-17)
    -------------------
    11:00      event: Sunday service
    ```

- [x] 2023-02-04-140555
  - howto
    ```powershell
    Get-MySchedule -Pattern recite
    ```
  - actual
    ```
    No content in C:\note\sched\notebook\ could be found matching the pattern 'recite'
    ```
  - expected
    ```
    No content in C:\note\sched\notebook\general\ could be found matching the pattern 'recite'
    ```

- [x] 2023-02-04-124905
  - howto
    - in sched.md
      ```
      # sched
      - what: Amazon Delivery
      - where
        - 25725 Jeronimo Rd, Mission Viejo, CA, 92691, United States
      - when
        - [ ] 2023-01-20
        - [ ] 2023-01-30
      ```
    - in powershell
      ```powershell
      Get-MySchedule
      ```
    - actual
      ```
      Saturday (2023-02-04)
      ---------------------
      00:00  [ ] todo: reappoint: meeting with Roi
      10:00      daily todo
      10:00      event: evangelism training
      13:00      event: phone interview

      Sunday (2023-02-05)
      -------------------
      11:00      event: Sunday service

      Monday (2023-02-06)
      -------------------
      16:00  [!] general offering

      Friday (2023-02-10)
      -------------------
      06:30      event: bible study men's
      ```

- [x] 2023-02-01-152740
  - howto
    ```powershell
    Get-MySchedule EvagelismTraining
    ```
  - actual
    ```
    Get-Content : Access to the path 'C:\Users\karlr\.android' is denied.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:410 char:15
    +             | Get-Content `
    +               ~~~~~~~~~~~
        + CategoryInfo          : PermissionDenied: (C:\Users\karlr\.android:String) [Get-Content], UnauthorizedAccessException
        + FullyQualifiedErrorId : GetContentReaderUnauthorizedAccessError,Microsoft.PowerShell.Commands.GetContentCommand

    Get-Content : Access to the path 'C:\Users\karlr\.dbus-keyrings' is denied.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:410 char:15
    +             | Get-Content `
    +               ~~~~~~~~~~~
        + CategoryInfo          : PermissionDenied: (C:\Users\karlr\.dbus-keyrings:String) [Get-Content], UnauthorizedAccessException
        + FullyQualifiedErrorId : GetContentReaderUnauthorizedAccessError,Microsoft.PowerShell.Commands.GetContentCommand

    Get-Content : Access to the path 'C:\Users\karlr\.dotnet' is denied.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:410 char:15
    +             | Get-Content `
    +               ~~~~~~~~~~~
        + CategoryInfo          : PermissionDenied: (C:\Users\karlr\.dotnet:String) [Get-Content], UnauthorizedAccessException
        + FullyQualifiedErrorId : GetContentReaderUnauthorizedAccessError,Microsoft.PowerShell.Commands.GetContentCommand

    Get-Content : Access to the path 'C:\Users\karlr\.nuget' is denied.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:410 char:15
    +             | Get-Content `
    +               ~~~~~~~~~~~
        + CategoryInfo          : PermissionDenied: (C:\Users\karlr\.nuget:String) [Get-Content], UnauthorizedAccessException
        + FullyQualifiedErrorId : GetContentReaderUnauthorizedAccessError,Microsoft.PowerShell.Commands.GetContentCommand

    ...
    ```

- [x] 2023-02-01-121902
  - howto
    ```powershell
    Get-MySchedule
    ```
  - actual
    ```
    Wednesday (2023-02-01)
    ----------------------
    00:00  [ ] todo: reappoint: meeting with Roi
    10:00      daily todo
    11:00      event: Sunday service
    ```
  - expected
    ```
    Wednesday (2023-02-01)
    ----------------------
    00:00  [ ] todo: reappoint: meeting with Roi
    10:00      daily todo
    ```

- [x] 2023-01-11-173519

  - howto
    - in powershell

      ```powershell
      Get-MySchedule -Subdirectory homework -StartDate 2023-01-09
      ```
    - in ``sched.md``

      ```
      # sched
      - what
        - recite Philippians
      - every: mon
      - type: todayonly
      ```
  - actual

    ```
    Monday (2023-01-09)
    -------------------
    23:00      Change and Growth Plan
    23:00      @{recite Philippians=}
    ```
  - expected

    ```
    Monday (2023-01-09)
    -------------------
    23:00      Change and Growth Plan
    23:00      recite Philippians
    ```

- [x] 2023-01-11-170506

  - actual
    - ``todo.md`` in neovim

      ```
      - [ ] Domino's Pizza jacket
        - link
          - retrieved: 2023-01-07
          - list
            - 
              - what: tracking
              - url: https://www.htgdominos.com/myaccount.asp
            - 
              - what: invoice
              - url: \doc\My\invoice_-_2023-01-07_HtgDominos.pdf
      ```
    - ``todo.md`` in MarkText
      ![Capture_2023-01-11-163152](./res/Screenshot_2023-01-11_163152.png)
  - workaround
    - ``todo.md`` in neovim

      ```
      - [ ] Domino's Pizza jacket
        - link
          - retrieved: 2023-01-07
          - list

            - 
              - what: tracking
              - url: https://www.htgdominos.com/myaccount.asp
            - 
              - what: invoice
              - url: \doc\My\invoice_-_2023-01-07_HtgDominos.pdf
      ```

## resolved

- [x] 2023-01-20-144308

  - what
    - ``MySchedule.ps1``: All defaults and constants should be recorded in ``/res/default.json``.
  - status
    - what: canceled
    - why: Close enough.

- [x] 2023-01-20-144402

  - what
    - File ``/res/default.json`` should be named ``setting.json``.

- [x] 2023-01-13-010203

  - actual

    ```
    C:\Users\karlr> Get-MySchedule -Subdirectory request -Pattern Partners -Mode Schedule
    The property 'Path' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:360 char:9
    +         $jsonFiles = $jsonFiles.Path
    +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    Test-Path : Cannot bind argument to parameter 'Path' because it is null.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:269 char:24
    +         if ((Test-Path $JsonFile)) {
    +                        ~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [Test-Path], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.TestPathCommand

    Friday (2023-01-13)
    -------------------
    11:00      evangelism
    11:00      ChangeAndGrowthPlan
    11:00      Partners
    23:00      Partners

    C:\Users\karlr> Get-MySchedule -Subdirectory request -Pattern Partners -Mode Tree
    The property 'Path' cannot be found on this object. Verify that the property exists.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:360 char:9
    +         $jsonFiles = $jsonFiles.Path
    +         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    Test-Path : Cannot bind argument to parameter 'Path' because it is null.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\MySchedule.ps1:269 char:24
    +         if ((Test-Path $JsonFile)) {
    +                        ~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [Test-Path], ParameterBindingValidationException
        + FullyQualifiedErrorId : ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.TestPathCommand

    Add-Member : Cannot add a member with the name "Partners" because a member with that name already exists. To overwrite the member anyway, add the Force parameter to
    your command.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\ScheduleObject.ps1:530 char:29
    +                     $tree | Add-Member `
    +                             ~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (@{evangelism=; ...an=; Partners=}:PSObject) [Add-Member], InvalidOperationException
        + FullyQualifiedErrorId : MemberAlreadyExists,Microsoft.PowerShell.Commands.AddMemberCommand

    - evangelism
      - when
        - 01/13/2023 11:00:00
      - type
        - todayonly
    - ChangeAndGrowthPlan
      - when
        - 01/13/2023 11:00:00
      - type
        - todayonly
    - Partners
      - when
        - 01/13/2023 11:00:00
      - type
        - todayonly
    ```

- [x] 2023-01-02-224101

  - howto

    ```powershell
    Find-MyTree -Subdirectory request -Tag coworker
    ```
  - actual

    ```
    - @{sus=; ihr=; oth=}
      - when
        - never
      - tag
        - susihroth
    ```
  - expected

    ```
    - sus
      - when
        - never
      - tag
        - susihroth
    - ihr
      - when
        - never
      - tag
        - susihroth
    - oth
      - when
        - never
      - tag
        - susihroth
    ```

- [x] 2022-11-10-003045

  - howto

    ```
    \shortcut\bin\tagsearch.bat request self
    ```

  - actual

    ```
    The property 'Name' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\devlib\powershell\PsSchedule\script
    \ScheduleObject.ps1:407 char:21
    +                 if ($Name -in $properties.Name) {
    +                     ~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundExc
       eption
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    The property 'Name' cannot be found on this object. Verify that the
    property exists.
    At C:\Users\karlr\OneDrive\Documents\devlib\powershell\PsSchedule\script
    \ScheduleObject.ps1:407 char:21
    +                 if ($Name -in $properties.Name) {
    +                     ~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundExc
       eption
        + FullyQualifiedErrorId : PropertyNotFoundStrict

    - tag
      - self
    - what
      - a safe means to use a device in the vicinity of a high-bandwidth ISP
    - tag
      - self, team evangelism
    - what
      - excitement for the gospel
      - boldness to speak
      - right words to say
    - what
      - request
      - that I can learn how to evangelize
      - that I can learn how to learn how to evangelize
    - tag
      - self
    ```

  - expected

    ```
    - tag
      - self
    - what
      - a safe means to use a device in the vicinity of a high-bandwidth ISP
    - tag
      - self, team evangelism
    - what
      - excitement for the gospel
      - boldness to speak
      - right words to say
    - tag
      - self
    - what
      - that I can learn how to evangelize
      - that I can learn how to learn how to evangelize
    ```

  - cause

    - the latest refactor to accomodate the new tree form
      - as in ``"I wish" 2022-11-09-175458``
      - messes up trees at Level 2 that don't have inline branches

- [x] 2022-11-08-125240

  - solution: non-issue

  - howto

    - in ``sched.md``

      ```
      # sched
      - what: Amazon delivery
      - when
        - [ ] 2022-11-02-1000
      - type: todo
      - every: none
      ```

    - cmd

      ```
      \shortcut\bin\sched.bat
      ```

  - actual

    ```
    Tuesday (2022-11-08)
    --------------------
    00:01      Amazon delivery
    ```

  - expected

    ```
    Tuesday (2022-11-08)
    --------------------
    10:00      Amazon delivery
    ```

- [x] 2022-11-06-114157

  - howto
    ``Get-MarkdownTable``

  - actual

    ```
    ...
    @{when=11/10/2022 18:30:00; what=Homegroup Bible Study; who:=; where=; type=event}
    ...
    ```

  - expected

    ```
    ...
    @{when=11/10/2022 18:30:00; what=Homegroup Bible Study; who=; where=; type=event}
    ...
    ```

- [x] 2022-11-05-140003

  - actual
    - ``todo`` items are treated as one-day events
  - expected
    - ``todo`` items are treated as action items to be completed, starting at ``when``

- [x] 2022-11-03-150245

  - actual

    ```
    C:\Users\karlr> sched.bat -subdir request

    Thursday (2022-11-03)
    ---------------------
    22:00      friend
    22:00      workplace
    22:00      cbcmbs
    22:00      self
    22:00      church
    22:00      team evangelism
    22:00      coworkers
    22:00      leaders
    ```

  - cause

    - ``script\ScheduleObject.ps1:919-920``

      ```powershell
      switch -Regex ($schedEvery) {
          '\w+(\s*,\s*\w+)+' {
      ```

  - solution

    ```powershell
    switch -Regex ($schedEvery) {
        '\w+(\s*,\s*\w+)*' {
    ```

- [x] 2022-10-26-170128

  - howto
    ``C:\shortcut\bin\sched.bat``

  - actual

    ```
    Add-Member : Cannot add a member with the name "retrieved" because a member with
    that name already exists. To overwrite the member anyway, add the Force parameter
    to your command.
    At C:\Users\karlr\OneDrive\Documents\devlib\powershell\PsSchedule\script\ScheduleOb
    ject.ps1:458 char:23
    +             $parent | Add-Member `
    +                       ~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (@{sched=System....ved=2022-10-09}
       :PSObject) [Add-Member], InvalidOperationException
        + FullyQualifiedErrorId : MemberAlreadyExists,Microsoft.PowerShell.Commands.Ad
       dMemberCommand

    The property 'sched' cannot be found on this object. Verify that the property
    exists.
    At C:\Users\karlr\OneDrive\Documents\devlib\powershell\PsSchedule\script\ScheduleOb
    ject.ps1:211 char:24
    +                 return $what.sched `
    +                        ~~~~~~~~~~~~~
        + CategoryInfo          : NotSpecified: (:) [], PropertyNotFoundException
        + FullyQualifiedErrorId : PropertyNotFoundStrict
    ```

  - cause

    1. Line 454: failure to use proper binding: ``$content``
    2. Line 211: failure to account for failable return value from ``Get-MarkdownTable``

- [x] 2022-10-21-121845

  - howto
    ``C:\shortcut\bin\sched.bat``

  - actual

    ```
    Add-Member : Cannot add a member with the name "https" because a member with that
    name already exists. To overwrite the member anyway, add the Force parameter to
    your command.
    At C:\Users\karlr\OneDrive\Documents\devlib\powershell\PsSchedule\script\ScheduleOb
    ject.ps1:445 char:23
    +             $parent | Add-Member `
    +                       ~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (@{https=//revol...om/goto/giving}
       :PSObject) [Add-Member], InvalidOperationException
        + FullyQualifiedErrorId : MemberAlreadyExists,Microsoft.PowerShell.Commands.Ad
       dMemberCommand
    ```

  - cause
    In a schedule file:

    ```
    - url
      - https://revolvebiblechurch.ccbchurch.com/goto/giving
      - https://pushpay.com/g/compasschurch?r=weekly&src=hpp
    ```

    Web links are being parsed like node names.

  - solution

    - require inline branches to be spaced:
      - accepted
        ``- what: daily todo``
      - not accepted
        ``- what:daily todo``

---
[← Go Back](../readme.md)

