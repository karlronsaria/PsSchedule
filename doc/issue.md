# issue
- [ ] 2023_08_01_171729
  - actual
    ```
    C:\Users\karlr> Get-MySchedule

    Tuesday (2023_08_01)
    --------------------
    00:00  [ ] todo: Walmart Delivery
    00:00  [ ] todo: Amazon Delivery
    00:00  [ ] todo: reappoint: meet with Roi
    00:00  [ ] todo: Amazon Delivery
    00:00  [ ] todo: Amazon Delivery
    10:00      daily todo
    17:14      {resume and hiring, 2023_04_27_1930}
    Find-Subtree : Cannot process argument transformation on parameter 'Parent'. Cannot convert value to type System.String.
    At C:\Users\karlr\OneDrive\Documents\WindowsPowerShell\Scripts\PsSchedule\script\ScheduleObject.ps1:179 char:21
    +             -Parent $ActionItem.what
    +                     ~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidData: (:) [Find-Subtree], ParameterBindingArgumentTransformationException
        + FullyQualifiedErrorId : ParameterArgumentTransformationError,Find-Subtree

    18:30      event: bible study men's

    Saturday (2023_08_05)
    ---------------------
    13:30      event: meet with Jesse Luna
    14:30      ---

    Sunday (2023_08_06)
    -------------------
    11:00      event: Sunday service

    Monday (2023_08_07)
    -------------------
    16:00  [!] general offering
    ```

- [ ] 2023_02_07_212709
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
          - when: 2023_02_04_1300
          - type: event
          - every: none
        - personal interview
          - where
            - address: 25652 Crown Valley Pkwy Suite F-1, Ladera Ranch, CA 92694
          - when: 2023_02_08_1300
          - type: event
          - every: none
      ```
  - actual
    ```
    Tuesday (2023_02_07)
    --------------------
    21:28      @{phone interview=; personal interview=}
    ```

- [ ] 2023_02_06_092921
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

- [x] 2023_02_04_140555
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

- [x] 2023_02_04_124905
  - howto
    - in sched.md
      ```
      # sched
      - what: Amazon Delivery
      - where
        - 25725 Jeronimo Rd, Mission Viejo, CA, 92691, United States
      - when
        - [ ] 2023_01_20
        - [ ] 2023_01_30
      ```
    - in powershell
      ```powershell
      Get-MySchedule
      ```
    - actual
      ```
      Saturday (2023_02_04)
      ---------------------
      00:00  [ ] todo: reappoint: meeting with Roi
      10:00      daily todo
      10:00      event: evangelism training
      13:00      event: phone interview

      Sunday (2023_02_05)
      -------------------
      11:00      event: Sunday service

      Monday (2023_02_06)
      -------------------
      16:00  [!] general offering

      Friday (2023_02_10)
      -------------------
      06:30      event: bible study men's
      ```

- [x] 2023_02_01_152740
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

- [x] 2023_02_01_121902
  - howto
    ```powershell
    Get-MySchedule
    ```
  - actual
    ```
    Wednesday (2023_02_01)
    ----------------------
    00:00  [ ] todo: reappoint: meeting with Roi
    10:00      daily todo
    11:00      event: Sunday service
    ```
  - expected
    ```
    Wednesday (2023_02_01)
    ----------------------
    00:00  [ ] todo: reappoint: meeting with Roi
    10:00      daily todo
    ```

- [ ] 2023_01_20_144131

  - what
    - ``Get-MySchedule``: ``Extension`` parameter is never used due to all work files having the markdown ``*.md`` extension.

- [x] 2023_01_11_173519
  
  - howto
    - in powershell
      
      ```powershell
      Get-MySchedule -Subdirectory homework -StartDate 2023_01_09
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
    Monday (2023_01_09)
    -------------------
    23:00      Change and Growth Plan
    23:00      @{recite Philippians=}
    ```
  - expected
    
    ```
    Monday (2023_01_09)
    -------------------
    23:00      Change and Growth Plan
    23:00      recite Philippians
    ```

- [x] 2023_01_11_170506
  
  - actual
    - ``todo.md`` in neovim
      
      ```
      - [ ] Domino's Pizza jacket
        - link
          - retrieved: 2023_01_07
          - list
            - 
              - what: tracking
              - url: https://www.htgdominos.com/myaccount.asp
            - 
              - what: invoice
              - url: \doc\My\invoice_-_2023_01_07_HtgDominos.pdf
      ```
    - ``todo.md`` in MarkText
      ![Capture_2023_01_11_163152](./res/Screenshot_2023-01-11_163152.png)
  - workaround
    - ``todo.md`` in neovim
      
      ```
      - [ ] Domino's Pizza jacket
        - link
          - retrieved: 2023_01_07
          - list

            - 
              - what: tracking
              - url: https://www.htgdominos.com/myaccount.asp
            - 
              - what: invoice
              - url: \doc\My\invoice_-_2023_01_07_HtgDominos.pdf
      ```

- [ ] 2023_01_10_230005
  
  - howto
    - in powershell
      
      ```powershell
      $tree = cat .\todo_-_2022_12_16.md | Get-MarkdownTable
      $tree.lookup | Write-MarkdownTree
      ```
    - in ``todo_-_2022_12_16.md``
      
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
            - retrieved: 2023_01_10
      - howto: remove windshield glare
        - [ ] learn
        - [x] find
          - link
            - search
              - STOP Auto Glass GLARE & WATER SPOTS....FOREVER!!!!!
              - Sweet Project Cars
              - YouTube
            - retrieved: 2023_01_10
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
            - retrieved: 2023_01_10
      - remove windshield glare
        - [ ] learn
        - [x] find
          - link
            - search
              - STOP Auto Glass GLARE & WATER SPOTS....FOREVER!!!!!
              - Sweet Project Cars
              - YouTube
            - retrieved: 2023_01_10
    - learn
      - [ ] webassembly
        - [ ] link video in listen-later playlist
      - [ ] Hindley-Milner type system
    ```

- [ ] 2022_10_27_180542
  
  - actual
    - action items with header levels other than 3 are ignored

## resolved

- [x] 2023_01_20_144308

  - what
    - ``MySchedule.ps1``: All defaults and constants should be recorded in ``/res/default.json``.
  - status
    - what: canceled
    - why: Close enough.

- [x] 2023_01_20_144402

  - what
    - File ``/res/default.json`` should be named ``setting.json``.

- [x] 2023_01_13_010203
  
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
    
    Friday (2023_01_13)
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

- [x] 2023_01_02_224101
  
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

- [x] 2022_11_10_003045
  
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
      - as in ``"I wish" 2022_11_09_175458``
      - messes up trees at Level 2 that don't have inline branches

- [x] 2022_11_08_125240
  
  - solution: non-issue
  
  - howto
    
    - in ``sched.md``
      
      ```
      # sched
      - what: Amazon delivery
      - when
        - [ ] 2022_11_02_1000
      - type: todo
      - every: none
      ```
    
    - cmd
      
      ```
      \shortcut\bin\sched.bat
      ```
  
  - actual
    
    ```
    Tuesday (2022_11_08)
    --------------------
    00:01      Amazon delivery
    ```
  
  - expected
    
    ```
    Tuesday (2022_11_08)
    --------------------
    10:00      Amazon delivery
    ```

- [x] 2022_11_06_114157
  
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

- [x] 2022_11_05_140003
  
  - actual
    - ``todo`` items are treated as one-day events
  - expected
    - ``todo`` items are treated as action items to be completed, starting at ``when``

- [x] 2022_11_03_150245
  
  - actual
    
    ```
    C:\Users\karlr> sched.bat -subdir request
    
    Thursday (2022_11_03)
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

- [x] 2022_10_26_170128
  
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
        + CategoryInfo          : InvalidOperation: (@{sched=System....ved=2022_10_09}
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

- [x] 2022_10_21_121845
  
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
[Back to Readme](../readme.md)

