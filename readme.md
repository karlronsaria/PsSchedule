# wish
I wish
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
- [x] 2022_10_26_170128
  - process
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
  - process
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


