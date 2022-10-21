# wish
I wish
- [ ] I could see expired action items from earlier today
- [ ] I could see high-priority deadlines within a week or month's notice but low-priority deadlines within a day's notice
- [x] I wish I could access an action item's file by selecting from a numbered list
  - karlr: Why not just use 'sls' or 'grep'?
  - solution: C:\shortcut\bin\schedsearch.bat
- [x] I could parse text rendered by the ``Write-*`` cmdlets but still see different-colored text
- [x] I could see today's work schedule

# issue
- 2022_10_21_121845
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


