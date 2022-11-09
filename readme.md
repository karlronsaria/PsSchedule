# wish
I wish
- [ ] I could write action items in list form under a single ``sched`` heading, using the ``what`` field as the title
  - example
    - typical form
      ```
      # sched
      - what: read
      - when: mon-1800
      - every: week
      - type: routine

      # sched
      - what: write
      - when: tue-1800
      - every: week
      - type: routine
      ```
    - new form
      ```
      # sched
      - read
        - when: mon-1800
        - every: week
        - type: routine
      - write
        - when: tue-1800
        - every: week
        - type: routine
      ```
- [ ] I could see expired action items from earlier today
- [ ] I could see high-priority deadlines within a week or month's notice but low-priority deadlines within a day's notice
- [x] I could schedule an action item for the same time every monday, friday, and saturday
  - solution
    - refactor: ``every' = every union 2^(Mon + Tue + Wed + ... + Sun)``
      ```
      example
          every: Mon, Tue, Wed, Fri
      thus
          every = (Mon: (0|1), Tue: (0|1), ... Sun: (0|1))
          every = (2, 2, 2, 2, 2, 2, 2)
          every = 2^7
          every = 2^(Mon + Tue + Wed + ... + Sun)
      ```
    - example

      ```
      # sched
      - what: college development course
      - when: 1000
      - every: Mon, Wed, Fri
      - type: routine
      ```
      - above is equivalent to

      ```
      # sched
      - what: college development course
      - when: mon-1000
      - every: week
      - type: routine

      # sched
      - what: college development course
      - when: wed-1000
      - every: week
      - type: routine

      # sched
      - what: college development course
      - when: fri-1000
      - every: week
      - type: routine
      ```
- [x] I wish I could access an action item's file by selecting from a numbered list
  - karlr: Why not just use 'sls' or 'grep'?
  - solution: C:\shortcut\bin\schedsearch.bat
- [x] I could parse text rendered by the ``Write-*`` cmdlets but still see different-colored text
- [x] I could see today's work schedule

# issue
- [ ] 2022_10_27_180542
  - actual
    - action items with header levels other than 3 are ignored
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


